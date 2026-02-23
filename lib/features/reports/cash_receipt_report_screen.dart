import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/firm_data_service.dart';
import '../../core/services/powersync_service.dart';
import '../buyer/buyer_ledger_pdf.dart';

class CashReceiptReportScreen extends StatefulWidget {
  const CashReceiptReportScreen({super.key});

  @override
  State<CashReceiptReportScreen> createState() =>
      _CashReceiptReportScreenState();
}

class _CashReceiptReportScreenState extends State<CashReceiptReportScreen> {
  final buyerCodeCtrl = TextEditingController();

  String buyerName = '';
  bool isLoading = false;
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();

  List<Map<String, dynamic>> ledger = [];

  @override
  void dispose() {
    buyerCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => fromDate = picked);
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => toDate = picked);
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

  Future<void> _generateReport() async {
    final code = buyerCodeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('कृपया पार्टी कोड टाका')));
      return;
    }

    await _lookupBuyer();
    if (buyerName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('पार्टी सापडली नाही')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final firmId = await FirmDataService.getActiveFirmId();
      if (firmId == null) throw Exception('कोणताही सक्रिय फर्म नाही');

      final fromStr = DateFormat('yyyy-MM-dd').format(fromDate);
      final toStr = DateFormat('yyyy-MM-dd').format(toDate);

      final openingRes = await powerSyncDB.getAll(
        'SELECT opening_balance FROM buyers WHERE firm_id = ? AND code = ?',
        [firmId, code],
      );
      double opening = (openingRes.isNotEmpty
                  ? openingRes.first['opening_balance'] as num?
                  : 0)
              ?.toDouble() ??
          0.0;

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

      final txns = await powerSyncDB.getAll(
        '''SELECT created_at as date, 'खाते जमा (माल विक्री)' as type,
                  parchi_id as ref, net as amount
           FROM transactions
           WHERE firm_id = ? AND buyer_code = ?
             AND date(created_at) >= date(?) AND date(created_at) <= date(?)''',
        [firmId, code, fromStr, toStr],
      );

      final pays = await powerSyncDB.getAll(
        '''SELECT created_at as date, 'रोख जमा' as type,
                  'जमा (' || payment_mode || ')' as ref, amount as amount
           FROM payments
           WHERE firm_id = ? AND buyer_code = ?
             AND date(created_at) >= date(?) AND date(created_at) <= date(?)''',
        [firmId, code, fromStr, toStr],
      );

      final all = [...txns, ...pays];
      all.sort((a, b) =>
          DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

      double running = opening;
      final result = <Map<String, dynamic>>[
        {
          'date': null,
          'type': 'Opening Balance',
          'ref': '',
          'udhari': 0.0,
          'jama': 0.0,
          'balance': running,
        }
      ];

      for (final row in all) {
        final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
        final isSale = row['type'] == 'खाते जमा (माल विक्री)';

        final udhari = isSale ? amount : 0.0;
        final jama = isSale ? 0.0 : amount;

        running += udhari;
        running -= jama;

        result.add({
          'date': row['date'],
          'type': row['type'],
          'ref': row['ref'],
          'udhari': udhari,
          'jama': jama,
          'balance': running,
        });
      }

      setState(() {
        ledger = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('त्रुटी: $e')));
      }
    }
  }

  Future<void> _previewPdf() async {
    await BuyerLedgerPdf.generatePreview(
      firmName: 'Bharat Mandi',
      buyerName: buyerName,
      buyerCode: buyerCodeCtrl.text.trim().toUpperCase(),
      fromDate: fromDate,
      toDate: toDate,
      ledger: ledger,
    );
  }

  Future<void> _sharePdf() async {
    final file = await BuyerLedgerPdf.generateFile(
      firmName: 'Bharat Mandi',
      buyerName: buyerName,
      buyerCode: buyerCodeCtrl.text.trim().toUpperCase(),
      fromDate: fromDate,
      toDate: toDate,
      ledger: ledger,
    );
    await Share.shareXFiles([XFile(file.path)],
        text: 'Cash Receipt Report - $buyerName');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('कॅश रिसीट रिपोर्ट'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: ledger.isEmpty ? null : _previewPdf,
            tooltip: 'प्रिंट/PDF प्रीव्ह्यू',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: ledger.isEmpty ? null : _sharePdf,
            tooltip: 'PDF शेअर',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: buyerCodeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'पार्टी कोड',
                    hintText: 'उदा. B001',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _lookupBuyer(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    buyerName.isEmpty
                        ? 'पार्टी नाव: -'
                        : 'पार्टी नाव: $buyerName',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFromDate,
                        icon: const Icon(Icons.date_range),
                        label: Text(
                            'पासून: ${DateFormat('dd-MM-yyyy').format(fromDate)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickToDate,
                        icon: const Icon(Icons.date_range),
                        label: Text(
                            'पर्यंत: ${DateFormat('dd-MM-yyyy').format(toDate)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _generateReport,
                    icon: const Icon(Icons.search),
                    label: const Text('रिपोर्ट तयार करा'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ledger.isEmpty
                    ? const Center(child: Text('रिपोर्ट उपलब्ध नाही'))
                    : ListView.builder(
                        itemCount: ledger.length,
                        itemBuilder: (context, index) {
                          final row = ledger[index];
                          final date = row['date'] == null
                              ? '-'
                              : DateFormat('dd-MM-yyyy')
                                  .format(DateTime.parse(row['date']));
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: ListTile(
                              title: Text('${row['type']} • $date'),
                              subtitle: Text('Ref: ${row['ref']}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if ((row['udhari'] as num?)?.toDouble() != 0)
                                    Text(
                                        'खाते: ₹${((row['udhari'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}'),
                                  if ((row['jama'] as num?)?.toDouble() != 0)
                                    Text(
                                        'जमा: ₹${((row['jama'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}'),
                                  Text(
                                      'बाकी: ₹${((row['balance'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
