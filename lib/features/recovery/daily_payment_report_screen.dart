import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/services/powersync_service.dart';

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
      // Get today's date range
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final startStr = startOfDay.toIso8601String();
      final endStr = endOfDay.toIso8601String();

      // Query 1: Get all payments for today, grouped by buyer
      final paymentsResult = await powerSyncDB.getAll(
        '''SELECT 
             buyer_code, 
             buyer_name, 
             SUM(amount) as total_amount,
             COUNT(*) as transaction_count
           FROM payments 
           WHERE created_at >= ? AND created_at < ?
           GROUP BY buyer_code, buyer_name
           ORDER BY buyer_name ASC''',
        [startStr, endStr],
      );

      // Query 2: Get transaction history (sales) for today
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
           WHERE buyer_code IS NOT NULL AND created_at >= ? AND created_at < ?
           ORDER BY created_at DESC''',
        [startStr, endStr],
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
      print('❌ Error loading payment report: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटी: $e')),
        );
      }
    }
  }

  /// Format date for display
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  /// Format currency
  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('आज का जमा रिपोर्ट'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Display
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.blue),
                          const SizedBox(width: 12),
                          Text(
                            'तारीख: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Daily Payment Summary Section
                  Text(
                    'आज का जमा सारांश',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Payment List
                  if (dailyPayments.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'आज कोई जमा नहीं',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        // Header Row
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'खरीददार नाम',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'जमा राशि',
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Payment Rows
                        ...dailyPayments.map((payment) {
                          final buyerName =
                              payment['buyer_name'] as String? ?? '';
                          final amount =
                              (payment['total_amount'] as num?)?.toDouble() ??
                                  0.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    buyerName,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    _formatCurrency(amount),
                                    textAlign: TextAlign.right,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                        // Divider
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(thickness: 2),
                        ),

                        // Total Row
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'कुल जमा',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                _formatCurrency(totalPaymentAmount),
                                textAlign: TextAlign.right,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                      fontSize: 18,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),

                  // Transaction History Section
                  Text(
                    'आज का लेनदेन इतिहास',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  if (transactionHistory.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'आज कोई लेनदेन नहीं',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: transactionHistory.map((transaction) {
                        final buyerName =
                            transaction['buyer_name'] as String? ?? '';
                        final produceName =
                            transaction['produce_name'] as String? ?? '';
                        final quantity =
                            (transaction['quantity'] as num?)?.toDouble() ??
                                0.0;
                        final rate =
                            (transaction['rate'] as num?)?.toDouble() ?? 0.0;
                        final gross =
                            (transaction['gross'] as num?)?.toDouble() ?? 0.0;
                        final createdAt =
                            transaction['created_at'] as String? ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Buyer name and time
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        buyerName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      _formatDate(createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Produce details
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'माल: $produceName',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'मात्रा: ${quantity.toStringAsFixed(2)} | दर: ₹${rate.toStringAsFixed(2)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey[600],
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'कुल',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey,
                                              ),
                                        ),
                                        Text(
                                          _formatCurrency(gross),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 20),

                  // Refresh Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadDailyPaymentReport,
                      icon: const Icon(Icons.refresh),
                      label: const Text('रिफ्रेश करें'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
