import 'package:flutter/material.dart';
import '../../../../../core/services/powersync_service.dart';
import '../../features/recovery/payment_model.dart';
import '../../features/recovery/payment_detail_screen.dart';

class PaymentListScreen extends StatefulWidget {
  final String? buyerCode; // Optional: filter by buyer code

  const PaymentListScreen({
    super.key,
    this.buyerCode,
  });

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  List<Payment> payments = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  /// Load all payments or filter by buyer code
  Future<void> _loadPayments() async {
    setState(() => isLoading = true);

    try {
      late List<Map<String, dynamic>> results;

      if (widget.buyerCode != null && widget.buyerCode!.isNotEmpty) {
        // Load payments for specific buyer
        results = await powerSyncDB.getAll(
          'SELECT * FROM payments WHERE buyer_code = ? ORDER BY created_at DESC',
          [widget.buyerCode],
        );
      } else {
        // Load all payments
        results = await powerSyncDB.getAll(
          'SELECT * FROM payments ORDER BY created_at DESC',
          [],
        );
      }

      final loadedPayments = results.map((r) => Payment.fromMap(r)).toList();

      setState(() {
        payments = loadedPayments;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading payments: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटी: $e')),
        );
      }
    }
  }

  /// Filter payments by search query
  List<Payment> _getFilteredPayments() {
    if (searchQuery.isEmpty) {
      return payments;
    }

    return payments
        .where((payment) =>
            payment.buyer_name
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            payment.buyer_code
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
        .toList();
  }

  /// Navigate to payment detail screen
  void _openPaymentDetail(Payment payment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentDetailScreen(
          paymentId: payment.id ?? '',
          buyerCode: payment.buyer_code,
        ),
      ),
    ).then((_) {
      // Refresh list when returning from detail screen
      _loadPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredPayments = _getFilteredPayments();

    return Scaffold(
      appBar: AppBar(
        title: const Text('जमा यादी'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'खरीददार नाम या कोड खोजें...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() => searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),

                // Payment List
                Expanded(
                  child: filteredPayments.isEmpty
                      ? Center(
                          child: Text(
                            searchQuery.isEmpty
                                ? 'कोई जमा नहीं'
                                : 'कोई मेल नहीं मिला',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredPayments.length,
                          itemBuilder: (context, index) {
                            final payment = filteredPayments[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: ListTile(
                                onTap: () => _openPaymentDetail(payment),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green[100],
                                  child: Text(
                                    payment.buyer_code.isNotEmpty
                                        ? payment.buyer_code[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  payment.buyer_name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'कोड: ${payment.buyer_code}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Text(
                                      payment.getFormattedDate(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey,
                                          ),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  payment.getFormattedAmount(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Summary Footer
                if (filteredPayments.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'कुल: ${filteredPayments.length} जमा',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'कुल राशि: ₹${filteredPayments.fold<double>(0, (sum, p) => sum + p.amount).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPayments,
        tooltip: 'रिफ्रेश करें',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
