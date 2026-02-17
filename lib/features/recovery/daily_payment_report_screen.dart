import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/powersync_service.dart';
import '../../core/services/firm_data_service.dart'; // ✅ NEW

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
        title: const Text('आज का जमा रिपोर्ट'),
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
                    // Summary Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'आज का सारांश',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('एकूण जमा:'),
                                Text(
                                  '₹${totalPaymentAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('एकूण व्यवहार:'),
                                Text(
                                  '${transactionHistory.length}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

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
                  ],
                ),
              ),
            ),
    );
  }
}
