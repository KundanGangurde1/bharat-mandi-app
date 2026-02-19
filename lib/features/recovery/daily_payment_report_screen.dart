import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/powersync_service.dart';
import '../../core/services/firm_data_service.dart';
import '../../core/utils/dashboard_helper.dart';

class DailyPaymentReportScreen extends StatefulWidget {
  const DailyPaymentReportScreen({super.key});

  @override
  State<DailyPaymentReportScreen> createState() =>
      _DailyPaymentReportScreenState();
}

class _DailyPaymentReportScreenState extends State<DailyPaymentReportScreen> {
  List<Map<String, dynamic>> dailyPayments = [];
  List<Map<String, dynamic>> transactionHistory = [];
  double totalPaymentAmount = 0.0;
  bool isLoading = true;
  String selectedDate = '';

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now().toString().split(' ')[0]; // Today's date
    _loadDailyPaymentReport();
  }

  /// Load today's payment report and transaction history
  Future<void> _loadDailyPaymentReport() async {
    setState(() => isLoading = true);

    try {
      // ✅ NEW: Get active firm ID
      final firmId = await FirmDataService.getActiveFirmId();
      if (firmId == null) {
        throw Exception('कोणताही सक्रिय फर्म नाही');
      }

      // Get today's date range
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final startStr = startOfDay.toIso8601String();
      final endStr = endOfDay.toIso8601String();

      // ✅ FIXED: Query 1 - Added firm_id filter
      final paymentsResult = await powerSyncDB.getAll(
        '''SELECT 
             buyer_code, 
             buyer_name, 
             SUM(amount) as total_amount,
             COUNT(*) as transaction_count
           FROM payments 
           WHERE firm_id = ? AND created_at >= ? AND created_at < ?
           GROUP BY buyer_code, buyer_name
           ORDER BY buyer_name ASC''',
        [firmId, startStr, endStr],
      );

      // ✅ FIXED: Query 2 - Added firm_id filter
      final transactionsResult = await powerSyncDB.getAll(
        '''SELECT 
             buyer_code,
             buyer_name,
             produce_name,
             quantity,
             rate,
             gross,
             created_at
           FROM transactions 
           WHERE firm_id = ? AND buyer_code IS NOT NULL AND created_at >= ? AND created_at < ?
           ORDER BY created_at DESC''',
        [firmId, startStr, endStr],
      );

      // Calculate total payments
      double total = 0.0;
      for (var payment in paymentsResult) {
        total += (payment['total_amount'] as num?)?.toDouble() ?? 0.0;
      }

      setState(() {
        dailyPayments = paymentsResult;
        transactionHistory = transactionsResult;
        totalPaymentAmount = total;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading daily payment report: $e');
      print('⚠️ Check if active firm is set');
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
        title: const Text('आजचा व्यापार'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDailyPaymentReport,
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
                    // Payments Section
                    if (dailyPayments.isNotEmpty) ...[
                      const Text(
                        'आज का जमा',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dailyPayments.length,
                        itemBuilder: (context, index) {
                          final payment = dailyPayments[index];
                          return Card(
                            child: ListTile(
                              title: Text(
                                '${payment['buyer_name']} (${payment['buyer_code']})',
                              ),
                              subtitle: Text(
                                '${payment['transaction_count']} व्यवहार',
                              ),
                              trailing: Text(
                                '₹${(payment['total_amount'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ] else
                      const Center(child: Text('आज कोणताही जमा नाही')),

                    const SizedBox(height: 32),

                    // ✅ आजचा सारांश - Summary Card at Bottom
                    const Text(
                      'आजचा सारांश',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    FutureBuilder<Map<String, dynamic>>(
                      future: DashboardHelper.getTodaysSummary(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'त्रुटी: डेटा लोड होऊ शकला नाही',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _loadDailyPaymentReport();
                                      });
                                    },
                                    child: const Text('पुन्हा प्रयत्न करा'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final data = snapshot.data ?? {};
                        final parchiCount = data['parchiCount'] as int? ?? 0;
                        final creditSales =
                            data['creditSales'] as double? ?? 0.0;
                        final cashSales = data['cashSales'] as double? ?? 0.0;
                        final totalSales = data['totalSales'] as double? ?? 0.0;
                        final paymentCount = data['paymentCount'] as int? ?? 0;
                        final paymentAmount =
                            data['paymentAmount'] as double? ?? 0.0;

                        return Card(
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
                                  // Row 1: एकुण पावती & आजची रोखविक्री
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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

                                  // Row 2: आजची थकबाकी & आजचा व्यापार
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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

                                  // Row 3: एकुण जमा पावती & आजची वसूली
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ✅ Summary row widget
  Widget _buildSummaryRow({
    required String label,
    required String value,
    required Color color,
    bool isFullWidth = false,
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
