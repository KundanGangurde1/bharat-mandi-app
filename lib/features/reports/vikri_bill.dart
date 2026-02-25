import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/firm_data_service.dart';
import '../../core/services/powersync_service.dart';
import 'vikri_bill_pdf.dart';

class VikriBillScreen extends StatefulWidget {
  const VikriBillScreen({super.key});

  @override
  State<VikriBillScreen> createState() => _VikriBillScreenState();
}

class _VikriBillScreenState extends State<VikriBillScreen> {
  final buyerCodeCtrl = TextEditingController();

  String buyerName = '';
  String activeFirmName = 'Bharat Mandi';
  String activeFirmMobile = '';
  bool isLoading = false;
  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> transactions = [];
  Map<String, double> expensesByType = {}; // expense_name -> total_amount
  double openingBalance = 0.0;
  double totalPayments = 0.0;

  @override
  void dispose() {
    buyerCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _lookupBuyer() async {
    final code = buyerCodeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => buyerName = '');
      return;
    }

    final firmId = await FirmDataService.getActiveFirmId();
    final buyerRes = await powerSyncDB.getAll(
      'SELECT name FROM buyers WHERE firm_id = ? AND code = ? AND active = 1',
      [firmId, code],
    );

    setState(() {
      buyerName =
          buyerRes.isEmpty ? '' : (buyerRes.first['name']?.toString() ?? '');
    });
  }

  Future<void> _loadFirmDetails() async {
    try {
      final data = await powerSyncDB.getAll(
        'SELECT name, phone FROM firms WHERE active = 1 LIMIT 1',
      );

      if (data.isNotEmpty) {
        setState(() {
          activeFirmName = data.first['name']?.toString() ?? 'Bharat Mandi';
          activeFirmMobile = data.first['phone']?.toString() ?? '';
        });
      }
    } catch (e) {
      print('❌ Error loading firm details: $e');
    }
  }

  /// Calculate all expenses for buyer on selected date
  Future<void> _calculateExpenses(
      String firmId, String buyerCode, String dateStr) async {
    try {
      expensesByType.clear();

      // Get all transactions for this buyer on this date
      final txns = await powerSyncDB.getAll(
        '''SELECT * FROM transactions
           WHERE firm_id = ? AND buyer_code = ?
             AND date(created_at) = date(?)
           ORDER BY created_at ASC''',
        [firmId, buyerCode, dateStr],
      );

      if (txns.isEmpty) return;

      // ============ STEP 1: Per-Produce Commission (TAP A) ============
      for (var txn in txns) {
        final produceCode = txn['produce_code']?.toString() ?? '';
        final buyerGross = (txn['gross'] as num?)?.toDouble() ?? 0.0;

        // Check if this produce has per-produce commission
        final produceData = await powerSyncDB.getAll(
          'SELECT commission_type, commission_value, commission_apply_on FROM produce WHERE firm_id = ? AND code = ?',
          [firmId, produceCode],
        );

        if (produceData.isNotEmpty) {
          final produce = produceData.first;
          final commissionType =
              produce['commission_type']?.toString() ?? 'DEFAULT';

          if (commissionType == 'PER_PRODUCE') {
            final applyOn = produce['commission_apply_on']?.toString() ?? '';
            final commValue =
                (produce['commission_value'] as num?)?.toDouble() ?? 0.0;

            if (applyOn == 'buyer' && commValue > 0) {
              final commAmount = (buyerGross * commValue) / 100;
              expensesByType['कमिशन (मालाप्रमाणे)'] =
                  (expensesByType['कमिशन (मालाप्रमाणे)'] ?? 0.0) + commAmount;
              print('✅ Per-Produce Commission: ₹$commAmount');
            }
          }
        }
      }

      // ============ STEP 2: Expense Type Commission (TAP B - Default) ============
      // Get "कमिशन" expense from expense_types
      final commissionExpense = await powerSyncDB.getAll(
        'SELECT commission, default_value, calculation_type, apply_on FROM expense_types WHERE firm_id = ? AND name = ? AND active = 1',
        [firmId, 'कमिशन'],
      );

      if (commissionExpense.isNotEmpty) {
        final commExp = commissionExpense.first;
        final applyOnType = (commExp['apply_on']?.toString() ?? '').trim();
        double commissionPct =
            (commExp['commission'] as num?)?.toDouble() ?? 0.0;

        // Fallback to default_value if commission is not set
        if (commissionPct <= 0) {
          final calcType =
              (commExp['calculation_type']?.toString() ?? '').trim();
          final defaultVal =
              (commExp['default_value'] as num?)?.toDouble() ?? 0.0;
          if (calcType == 'percentage' && defaultVal > 0) {
            commissionPct = defaultVal;
          }
        }

        if (commissionPct > 0 &&
            (applyOnType.isEmpty || applyOnType == 'buyer')) {
          for (var txn in txns) {
            final produceCode = txn['produce_code']?.toString() ?? '';

            // Check if this produce has per-produce commission
            final produceData = await powerSyncDB.getAll(
              'SELECT commission_type FROM produce WHERE firm_id = ? AND code = ?',
              [firmId, produceCode],
            );

            bool hasPerProduceComm = false;
            if (produceData.isNotEmpty) {
              hasPerProduceComm =
                  (produceData.first['commission_type']?.toString() ??
                          'DEFAULT') ==
                      'PER_PRODUCE';
            }

            // Only apply expense type commission if NOT per-produce
            if (!hasPerProduceComm) {
              final buyerGross = (txn['gross'] as num?)?.toDouble() ?? 0.0;
              final commAmount = (buyerGross * commissionPct) / 100;
              expensesByType['कमिशन'] =
                  (expensesByType['कमिशन'] ?? 0.0) + commAmount;
              print('✅ Expense Type Commission: ₹$commAmount');
            }
          }
        }
      }

      // ============ STEP 3: Other Expenses (Non-Commission) ============
      final otherExpenses = await powerSyncDB.getAll(
        '''SELECT et.id, et.name as expense_name, SUM(te.amount) as total_amount
           FROM transaction_expenses te
           LEFT JOIN expense_types et ON te.expense_type_id = et.id
           WHERE te.firm_id = ? 
           AND te.parchi_id IN (
             SELECT DISTINCT parchi_id FROM transactions 
             WHERE firm_id = ? AND buyer_code = ? AND date(created_at) = date(?)
           )
           AND (et.name IS NULL OR et.name != 'कमिशन')
           GROUP BY et.id, et.name''',
        [firmId, firmId, buyerCode, dateStr],
      );

      for (var exp in otherExpenses) {
        final expName = exp['expense_name']?.toString() ?? 'इतर खर्च';
        final amount = (exp['total_amount'] as num?)?.toDouble() ?? 0.0;
        if (amount > 0) {
          expensesByType[expName] = (expensesByType[expName] ?? 0.0) + amount;
          print('✅ Other Expense: $expName = ₹$amount');
        }
      }

      print('📊 Total Expenses: ${expensesByType.length} types');
    } catch (e) {
      print('❌ Error calculating expenses: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense calculation error: $e')),
        );
      }
    }
  }

  Future<void> _generateBill() async {
    final code = buyerCodeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('कृपया खरीददार कोड टाका')));
      return;
    }

    await _lookupBuyer();
    if (buyerName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('खरीददार सापडला नाही')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final firmId = await FirmDataService.getActiveFirmId();
      if (firmId == null) throw Exception('कोणताही सक्रिय फर्म नाही');

      await _loadFirmDetails();

      final fromStr = DateFormat('yyyy-MM-dd').format(selectedDate);

      // Get opening balance
      final openingRes = await powerSyncDB.getAll(
        'SELECT opening_balance FROM buyers WHERE firm_id = ? AND code = ?',
        [firmId, code],
      );
      double opening = (openingRes.isNotEmpty
                  ? openingRes.first['opening_balance'] as num?
                  : 0)
              ?.toDouble() ??
          0.0;

      // Get previous transactions balance
      final prevTxn = await powerSyncDB.getAll(
        '''SELECT IFNULL(SUM(net),0) as total FROM transactions
           WHERE firm_id = ? AND buyer_code = ? AND date(created_at) < date(?)''',
        [firmId, code, fromStr],
      );
      final prevPay = await powerSyncDB.getAll(
        '''SELECT IFNULL(SUM(amount),0) as total FROM payments
           WHERE firm_id = ? AND buyer_code = ? AND date(created_at) < date(?)''',
        [firmId, code, fromStr],
      );

      opening += (prevTxn.first['total'] as num?)?.toDouble() ?? 0.0;
      opening -= (prevPay.first['total'] as num?)?.toDouble() ?? 0.0;

      // Get transactions for selected date
      final txns = await powerSyncDB.getAll(
        '''SELECT * FROM transactions
           WHERE firm_id = ? AND buyer_code = ?
             AND date(created_at) = date(?)
           ORDER BY created_at ASC''',
        [firmId, code, fromStr],
      );

      // Get payments for selected date
      final pays = await powerSyncDB.getAll(
        '''SELECT IFNULL(SUM(amount),0) as total FROM payments
           WHERE firm_id = ? AND buyer_code = ?
             AND date(created_at) = date(?)''',
        [firmId, code, fromStr],
      );

      double totalPay = (pays.first['total'] as num?)?.toDouble() ?? 0.0;

      // Calculate all expenses
      await _calculateExpenses(firmId, code, fromStr);

      setState(() {
        transactions = txns;
        openingBalance = opening;
        totalPayments = totalPay;
        isLoading = false;
      });

      if (txns.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('या तारीखला या खरीददारासाठी कोणते लेनदेन नाही'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('त्रुटी: $e')));
      }
    }
  }

  /// Generate and Share Bill
  Future<void> _generateAndShareBill() async {
    if (transactions.isEmpty) return;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📄 बिल तैयार किया जा रहा है...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final doc = await VikriBillPdf.generateBuyerBill(
        firmName: activeFirmName,
        mobileNumber: activeFirmMobile,
        buyerName: buyerName,
        buyerCode: buyerCodeCtrl.text.trim().toUpperCase(),
        billDate: selectedDate,
        transactions: transactions,
        expensesByType: expensesByType,
        openingBalance: openingBalance,
        totalPayments: totalPayments,
      );

      if (mounted) {
        final bytes = await doc.save();
        final dir = await getTemporaryDirectory();
        final fileName =
            'vikri_bill_${buyerCodeCtrl.text.trim().toUpperCase()}_${DateFormat('ddMMyyyy').format(selectedDate)}.pdf';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'विक्री बिल - $buyerName',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('त्रुटी: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFirmDetails();
  }

  @override
  Widget build(BuildContext context) {
    final totalGross = transactions.fold<double>(
      0,
      (sum, txn) => sum + ((txn['gross'] as num?)?.toDouble() ?? 0.0),
    );

    final totalExpenses =
        expensesByType.values.fold<double>(0, (sum, val) => sum + val);

    final netAmount = totalGross + totalExpenses;

    final finalBalance = openingBalance + netAmount - totalPayments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('विक्री बिल'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (transactions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _generateAndShareBill,
              tooltip: 'बिल शेअर करा',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buyer Code Input
            TextField(
              controller: buyerCodeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'खरीददार कोड',
                hintText: 'उदा. B001',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _lookupBuyer(),
            ),
            const SizedBox(height: 12),

            // Buyer Name Display
            if (buyerName.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Text(
                        'खरीददार: $buyerName',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Date Picker
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.date_range),
              label: Text(
                'तारीख: ${DateFormat('dd-MM-yyyy').format(selectedDate)}',
              ),
            ),
            const SizedBox(height: 16),

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _generateBill,
                icon: const Icon(Icons.search),
                label: const Text('बिल तयार करा'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Loading or Results
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (transactions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'बिल विवरण:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Transactions List
                  ...transactions.map((txn) {
                    final produceName = txn['produce_name']?.toString() ?? '-';
                    final quantity =
                        (txn['quantity'] as num?)?.toDouble() ?? 0.0;
                    final rate = (txn['rate'] as num?)?.toDouble() ?? 0.0;
                    final gross = (txn['gross'] as num?)?.toDouble() ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(produceName),
                        subtitle: Text(
                          'वजन: ${quantity.toStringAsFixed(2)} × ₹${rate.toStringAsFixed(2)}',
                        ),
                        trailing: Text(
                          '₹${gross.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 16),
                  const Divider(thickness: 2),
                  const SizedBox(height: 12),

                  // Summary
                  _buildSummaryRow(
                    'एकुण रक्कम:',
                    totalGross.toStringAsFixed(2),
                  ),
                  const SizedBox(height: 12),

                  // Expenses Breakdown
                  if (expensesByType.isNotEmpty) ...[
                    const Text(
                      'एकुण खर्च:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...expensesByType.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                        child: _buildSummaryRow(
                          '  • ${entry.key}:',
                          entry.value.toStringAsFixed(2),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                  ],

                  _buildSummaryRow(
                    'एकुण खर्च:',
                    totalExpenses.toStringAsFixed(2),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'नेट रक्कम:',
                    netAmount.toStringAsFixed(2),
                    isBold: true,
                  ),
                  const SizedBox(height: 16),
                  const Divider(thickness: 2),
                  const SizedBox(height: 12),

                  // Balance Info
                  _buildSummaryRow(
                    'मांगील बाकी:',
                    openingBalance.toStringAsFixed(2),
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'आज जमा:',
                    totalPayments.toStringAsFixed(2),
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'एकुण बाकी:',
                    finalBalance.toStringAsFixed(2),
                    isBold: true,
                  ),

                  const SizedBox(height: 24),

                  // Share Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generateAndShareBill,
                      icon: const Icon(Icons.share),
                      label: const Text('बिल शेअर करा'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '₹$value',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }
}
