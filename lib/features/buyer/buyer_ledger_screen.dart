import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/powersync_service.dart';
import '../../core/services/firm_data_service.dart'; // ✅ NEW
import '../../features/buyer/buyer_ledger_pdf.dart';

class BuyerLedgerScreen extends StatefulWidget {
  final String buyerCode;
  final String buyerName;

  const BuyerLedgerScreen({
    super.key,
    required this.buyerCode,
    required this.buyerName,
  });

  @override
  State<BuyerLedgerScreen> createState() => _BuyerLedgerScreenState();
}

class _BuyerLedgerScreenState extends State<BuyerLedgerScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> ledger = [];

  DateTime? fromDate;
  DateTime? toDate;

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => fromDate = picked);
      _loadLedger();
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => toDate = picked);
      _loadLedger();
    }
  }

  Future<void> _loadLedger() async {
    setState(() => isLoading = true);

    try {
      // ✅ NEW: Get active firm ID
      final firmId = await FirmDataService.getActiveFirmId();
      if (firmId == null) {
        throw Exception('कोणताही सक्रिय फर्म नाही');
      }

      // ✅ FIXED: Added firm_id filter
      final buyerRes = await powerSyncDB.getAll(
        'SELECT opening_balance FROM buyers WHERE firm_id = ? AND code = ?',
        [firmId, widget.buyerCode],
      );

      double openingBalance =
          (buyerRes.first['opening_balance'] as num?)?.toDouble() ?? 0.0;

      String dateFilter = '';
      List<dynamic> txnParams = [firmId, widget.buyerCode]; // ✅ Added firmId
      List<dynamic> payParams = [firmId, widget.buyerCode]; // ✅ Added firmId

      if (fromDate != null) {
        final d = DateFormat('yyyy-MM-dd').format(fromDate!);
        dateFilter += ' AND date(created_at) >= date(?)';
        txnParams.add(d);
        payParams.add(d);
      }

      if (toDate != null) {
        final d = DateFormat('yyyy-MM-dd').format(toDate!);
        dateFilter += ' AND date(created_at) <= date(?)';
        txnParams.add(d);
        payParams.add(d);
      }

      // 🔥 PREVIOUS BALANCE (Before From Date)
      double previousBalance = openingBalance;

      if (fromDate != null) {
        final d = DateFormat('yyyy-MM-dd').format(fromDate!);

        // ✅ FIXED: Added firm_id filter
        final prevTxn = await powerSyncDB.getAll('''
          SELECT SUM(net) as total
          FROM transactions
          WHERE firm_id = ? AND buyer_code = ?
          AND date(created_at) < date(?)
        ''', [firmId, widget.buyerCode, d]);

        // ✅ FIXED: Added firm_id filter
        final prevPay = await powerSyncDB.getAll('''
          SELECT SUM(amount) as total
          FROM payments
          WHERE firm_id = ? AND buyer_code = ?
          AND date(created_at) < date(?)
        ''', [firmId, widget.buyerCode, d]);

        final txnTotal = (prevTxn.first['total'] as num?)?.toDouble() ?? 0.0;
        final payTotal = (prevPay.first['total'] as num?)?.toDouble() ?? 0.0;

        previousBalance += txnTotal;
        previousBalance -= payTotal;
      }

      // ✅ FIXED: Added firm_id filter
      final transactions = await powerSyncDB.getAll('''
        SELECT 
          created_at AS date,
          'पावती' AS type,
            ('पावती #' || parchi_id || ' • ' || IFNULL(produce_name, '') || ' • एकूण: ₹' || IFNULL(ROUND(gross, 2), 0) || ' • खर्च: ₹' || IFNULL(ROUND(total_expense, 2), 0)) AS ref,
          net AS amount
        FROM transactions
        WHERE firm_id = ? AND buyer_code = ?
        $dateFilter
      ''', txnParams);

      // ✅ FIXED: Added firm_id filter
      final payments = await powerSyncDB.getAll('''
        SELECT 
          created_at AS date,
          'जमा' AS type,
          'जमा (' || payment_mode || ')' AS ref,
          amount AS amount
        FROM payments
        WHERE firm_id = ? AND buyer_code = ?
        $dateFilter
      ''', payParams);

      final all = [...transactions, ...payments];

      all.sort((a, b) =>
          DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

      double runningBalance = previousBalance;
      final result = <Map<String, dynamic>>[];

      result.add({
        'date': null,
        'type': fromDate != null ? 'Previous Balance' : 'Opening Balance',
        'ref': '',
        'jama': 0.0,
        'udhari': 0.0,
        'balance': runningBalance,
      });

      for (final row in all) {
        final amount = (row['amount'] as num).toDouble();

        double jama = 0.0;
        double udhari = 0.0;

        if (row['type'] == 'पावती') {
          udhari = amount;
          runningBalance += udhari;
        } else {
          jama = amount;
          runningBalance -= jama;
        }

        result.add({
          'date': row['date'],
          'type': row['type'],
          'ref': row['ref'],
          'jama': jama,
          'udhari': udhari,
          'balance': runningBalance,
        });
      }

      setState(() {
        ledger = result;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Ledger error: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटी: $e')),
        );
      }
    }
  }

  Future<void> _shareLedger() async {
    final file = await BuyerLedgerPdf.generateFile(
      firmName: 'Bharat Mandi',
      buyerName: widget.buyerName,
      buyerCode: widget.buyerCode,
      fromDate: fromDate,
      toDate: toDate,
      ledger: ledger,
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Buyer Ledger – ${widget.buyerName}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ledger – ${widget.buyerName}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              BuyerLedgerPdf.generatePreview(
                firmName: 'Bharat Mandi',
                buyerName: widget.buyerName,
                buyerCode: widget.buyerCode,
                fromDate: fromDate,
                toDate: toDate,
                ledger: ledger,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareLedger,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromDate,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      fromDate == null
                          ? 'From Date'
                          : DateFormat('dd/MM/yyyy').format(fromDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickToDate,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      toDate == null
                          ? 'To Date'
                          : DateFormat('dd/MM/yyyy').format(toDate!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ledger.isEmpty
                    ? const Center(child: Text('कोणताही व्यवहार नाही'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('दिनांक')),
                            DataColumn(label: Text('तपशील')),
                            DataColumn(label: Text('Ref')),
                            DataColumn(label: Text('उधारी')),
                            DataColumn(label: Text('जमा')),
                            DataColumn(label: Text('शिल्लक')),
                          ],
                          rows: ledger.map((row) {
                            return DataRow(cells: [
                              DataCell(Text(
                                row['date'] == null
                                    ? '-'
                                    : DateFormat('dd/MM/yyyy').format(
                                        DateTime.parse(row['date']),
                                      ),
                              )),
                              DataCell(Text(row['type'])),
                              DataCell(Text(row['ref'].toString())),
                              DataCell(Text(
                                row['udhari'] > 0
                                    ? '₹${row['udhari'].toStringAsFixed(2)}'
                                    : '',
                              )),
                              DataCell(Text(
                                row['jama'] > 0
                                    ? '₹${row['jama'].toStringAsFixed(2)}'
                                    : '',
                              )),
                              DataCell(Text(
                                '₹${row['balance'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: row['balance'] >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
