import 'package:flutter/material.dart';
import '../../../core/services/powersync_service.dart';
import '../../../core/services/firm_data_service.dart';
import '../../../core/utils/dashboard_helper.dart';

class BusinessSummaryReportScreen extends StatefulWidget {
  const BusinessSummaryReportScreen({super.key});

  @override
  State<BusinessSummaryReportScreen> createState() =>
      _BusinessSummaryReportScreenState();
}

class _BusinessSummaryReportScreenState
    extends State<BusinessSummaryReportScreen> {
  bool isLoading = true;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  int parchiCount = 0;
  int paymentCount = 0;
  double creditSales = 0.0;
  double cashSales = 0.0;
  double totalSales = 0.0;
  double paymentAmount = 0.0;

  List<Map<String, dynamic>> expenseSummary = [];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  DateTime get _rangeStart =>
      DateTime(startDate.year, startDate.month, startDate.day);
  DateTime get _rangeEndExclusive =>
      DateTime(endDate.year, endDate.month, endDate.day)
          .add(const Duration(days: 1));
  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      await _loadReport();
    }
  }

  Future<void> _loadReport() async {
    setState(() => isLoading = true);

    try {
      final firmId = await FirmDataService.getActiveFirmId();
      if (firmId == null) {
        throw Exception('कोणताही सक्रिय फर्म नाही');
      }

      final startStr = _rangeStart.toIso8601String();
      final endStr = _rangeEndExclusive.toIso8601String();

      final parchiCountResult = await powerSyncDB.getAll(
        '''SELECT COUNT(DISTINCT parchi_id) as count FROM transactions
           WHERE firm_id = ? AND created_at >= ? AND created_at < ?''',
        [firmId, startStr, endStr],
      );

      final creditSalesResult = await powerSyncDB.getAll(
        '''SELECT IFNULL(SUM(CAST(net AS REAL)), 0) as total FROM transactions
           WHERE firm_id = ? AND buyer_code != 'R' AND created_at >= ? AND created_at < ?''',
        [firmId, startStr, endStr],
      );

      final cashSalesResult = await powerSyncDB.getAll(
        '''SELECT IFNULL(SUM(CAST(net AS REAL)), 0) as total FROM transactions
           WHERE firm_id = ? AND buyer_code = 'R' AND created_at >= ? AND created_at < ?''',
        [firmId, startStr, endStr],
      );

      final paymentCountResult = await powerSyncDB.getAll(
        '''SELECT COUNT(DISTINCT id) as count FROM payments
           WHERE firm_id = ? AND created_at >= ? AND created_at < ?''',
        [firmId, startStr, endStr],
      );

      final paymentAmountResult = await powerSyncDB.getAll(
        '''SELECT IFNULL(SUM(CAST(amount AS REAL)), 0) as total FROM payments
           WHERE firm_id = ? AND created_at >= ? AND created_at < ?''',
        [firmId, startStr, endStr],
      );

      final expenseRows = await powerSyncDB.getAll(
        '''SELECT
             et.name as expense_name,
             IFNULL(SUM(CAST(te.amount AS REAL)), 0) as total_amount
           FROM transaction_expenses te
           LEFT JOIN expense_types et ON te.expense_type_id = et.id
           WHERE te.firm_id = ? AND te.created_at >= ? AND te.created_at < ?
           GROUP BY et.name
           HAVING total_amount > 0
           ORDER BY et.name ASC''',
        [firmId, startStr, endStr],
      );

      final cSales = ((creditSalesResult.isNotEmpty
                  ? creditSalesResult.first['total'] as num?
                  : 0)
              ?.toDouble() ??
          0.0);
      final kSales = ((cashSalesResult.isNotEmpty
                  ? cashSalesResult.first['total'] as num?
                  : 0)
              ?.toDouble() ??
          0.0);

      setState(() {
        parchiCount = (parchiCountResult.isNotEmpty
                ? parchiCountResult.first['count'] as int?
                : 0) ??
            0;
        creditSales = cSales;
        cashSales = kSales;
        totalSales = cSales + kSales;
        paymentCount = (paymentCountResult.isNotEmpty
                ? paymentCountResult.first['count'] as int?
                : 0) ??
            0;
        paymentAmount = ((paymentAmountResult.isNotEmpty
                    ? paymentAmountResult.first['total'] as num?
                    : 0)
                ?.toDouble() ??
            0.0);
        expenseSummary = expenseRows;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटी: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('दैनिक पेमेंट रिपोर्ट'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
            tooltip: 'दिनांक निवडा',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
            tooltip: 'रिफ्रेश',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month,
                                color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'कालावधी: ${_fmt(startDate)} ते ${_fmt(endDate)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            TextButton(
                              onPressed: _pickDateRange,
                              child: const Text('बदला'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'आजचा सारांश',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.green.withOpacity(0.05),
                              Colors.blue.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSummaryRow(
                                      label: 'एकुण पावती:',
                                      value: parchiCount.toString(),
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildSummaryRow(
                                      label: 'आजची रोखविक्री:',
                                      value: DashboardHelper.formatCurrency(
                                          cashSales),
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSummaryRow(
                                      label: 'आजची थकबाकी:',
                                      value: DashboardHelper.formatCurrency(
                                          creditSales),
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildSummaryRow(
                                      label: 'आजचा व्यापार:',
                                      value: DashboardHelper.formatCurrency(
                                          totalSales),
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSummaryRow(
                                      label: 'एकुण जमा पावती:',
                                      value: paymentCount.toString(),
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildSummaryRow(
                                      label: 'आजची वसूली:',
                                      value: DashboardHelper.formatCurrency(
                                          paymentAmount),
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'खर्च प्रकारानुसार एकूण खर्च',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (expenseSummary.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('निवडलेल्या कालावधीत खर्च आढळला नाही.'),
                        ),
                      )
                    else
                      ...expenseSummary.map((e) {
                        final name = e['expense_name']?.toString().trim();
                        final expenseName = (name == null || name.isEmpty)
                            ? 'अज्ञात खर्च'
                            : name;
                        final amount =
                            (e['total_amount'] as num?)?.toDouble() ?? 0.0;

                        return Card(
                          child: ListTile(
                            leading: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Colors.deepOrange),
                            title: Text(expenseName),
                            trailing: Text(
                              DashboardHelper.formatCurrencyFull(amount),
                              style: const TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
