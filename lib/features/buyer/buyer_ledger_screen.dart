import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/powersync_service.dart';
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
      final buyerRes = await powerSyncDB.getAll(
        'SELECT opening_balance FROM buyers WHERE code = ?',
        [widget.buyerCode],
      );

      double openingBalance =
          (buyerRes.first['opening_balance'] as num?)?.toDouble() ?? 0.0;

      String dateFilter = '';

      List<dynamic> txnParams = [widget.buyerCode];
      List<dynamic> payParams = [widget.buyerCode];

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

      final transactions = await powerSyncDB.getAll(
        '''
      SELECT 
        created_at AS date,
        'पावती' AS type,
        parchi_id AS ref,
        net AS amount
      FROM transactions
      WHERE buyer_code = ?
      $dateFilter
      ''',
        txnParams,
      );

      final payments = await powerSyncDB.getAll(
        '''
      SELECT 
        created_at AS date,
        'जमा' AS type,
        'जमा (' || payment_mode || ')' AS ref,
        amount AS amount
      FROM payments
      WHERE buyer_code = ?
      $dateFilter
      ''',
        payParams,
      );

      final all = [...transactions, ...payments];

      all.sort((a, b) =>
          DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

      double runningBalance = openingBalance;
      final result = <Map<String, dynamic>>[];

      result.add({
        'date': null,
        'type': 'Opening Balance',
        'ref': '',
        'debit': 0.0,
        'credit': 0.0,
        'balance': runningBalance,
      });

      for (final row in all) {
        final amount = (row['amount'] as num).toDouble();

        double debit = 0.0;
        double credit = 0.0;

        if (row['type'] == 'पावती') {
          debit = amount;
          runningBalance += debit;
        } else {
          credit = amount;
          runningBalance -= credit;
        }

        result.add({
          'date': row['date'],
          'type': row['type'],
          'ref': row['ref'],
          'debit': debit,
          'credit': credit,
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
    }
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
              BuyerLedgerPdf.generate(
                firmName: 'Bharat Mandi',
                buyerName: widget.buyerName,
                buyerCode: widget.buyerCode,
                fromDate: fromDate,
                toDate: toDate,
                ledger: ledger,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 Date Filter Bar
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
                            DataColumn(label: Text('डेबिट')),
                            DataColumn(label: Text('क्रेडिट')),
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
                                row['debit'] > 0
                                    ? '₹${row['debit'].toStringAsFixed(2)}'
                                    : '',
                              )),
                              DataCell(Text(
                                row['credit'] > 0
                                    ? '₹${row['credit'].toStringAsFixed(2)}'
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
