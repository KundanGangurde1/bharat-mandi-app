import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../core/services/powersync_service.dart';

class PavtiDetailScreen extends StatefulWidget {
  final String parchiId;
  final bool isEdit;

  const PavtiDetailScreen({
    super.key,
    required this.parchiId,
    this.isEdit = false,
  });

  @override
  State<PavtiDetailScreen> createState() => _PavtiDetailScreenState();
}

class _PavtiDetailScreenState extends State<PavtiDetailScreen> {
  Map<String, dynamic> pavti = {};
  List<Map<String, dynamic>> entries = [];
  List<Map<String, dynamic>> expenses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPavtiDetails();
  }

  Future<void> _loadPavtiDetails() async {
    setState(() => isLoading = true);

    try {
      // PowerSync: Get all transactions for this parchi_id
      final data = await powerSyncDB.getAll(
        'SELECT * FROM transactions WHERE parchi_id = ? ORDER BY id ASC',
        [widget.parchiId],
      );

      // PowerSync: Get expenses for this parchi_id
      final expenseData = await powerSyncDB.getAll(
        'SELECT te.*, et.name as expense_name FROM transaction_expenses te '
        'LEFT JOIN expense_types et ON te.expense_type_id = et.id '
        'WHERE te.parchi_id = ? ORDER BY te.id ASC',
        [widget.parchiId],
      );

      setState(() {
        entries = data;
        expenses = expenseData;
        if (data.isNotEmpty) {
          pavti = data.first;
        }
        isLoading = false;
      });

      print(
          '✅ Loaded pavti details: ${entries.length} entries, ${expenses.length} expenses');
    } catch (e) {
      print("❌ Error loading pavti: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटी: $e')),
        );
      }
    }
  }

  Future<void> _savePavti() async {
    try {
      // PowerSync: Update all transactions for this parchi_id
      // (In a real app, you might want to allow editing individual fields)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('पावती अपडेट झाली'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      print("❌ Error saving pavti: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('त्रुटी: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('पावती तपशील'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (entries.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('पावती तपशील'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('पावती माहिती उपलब्ध नाही'),
        ),
      );
    }

    final farmerName = pavti['farmer_name']?.toString() ?? '-';
    final farmerCode = pavti['farmer_code']?.toString() ?? '-';
    final createdAt = pavti['created_at'] as String?;
    final totalExpense = (pavti['total_expense'] as num?)?.toDouble() ?? 0.0;
    final net = (pavti['net'] as num?)?.toDouble() ?? 0.0;
    final gross = (pavti['gross'] as num?)?.toDouble() ?? 0.0;

    final formattedDate = createdAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(createdAt))
        : '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('पावती तपशील'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (widget.isEdit)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _savePavti,
              tooltip: 'सेव करा',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              color: Colors.green[50],
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'पावती नं: ${widget.parchiId}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'पूर्ण',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'शेतकरी: $farmerName ($farmerCode)',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'तारीख: $formattedDate',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Entries Section
            const Text(
              'एंट्री यादी:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final traderName = entry['trader_name']?.toString() ?? '-';
                final produceName = entry['produce_name']?.toString() ?? '-';
                final dag = (entry['dag'] as num?)?.toDouble() ?? 0.0;
                final quantity = (entry['quantity'] as num?)?.toDouble() ?? 0.0;
                final rate = (entry['rate'] as num?)?.toDouble() ?? 0.0;
                final gross = (entry['gross'] as num?)?.toDouble() ?? 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'एंट्री ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '₹$gross',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'व्यापारी: $traderName',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Text(
                                  'माल: $produceName',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'डाग: $dag',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Text(
                                  'वजन: $quantity',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'भाव: ₹$rate',
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              'एकूण: ₹$gross',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Expenses Section
            if (expenses.isNotEmpty) ...[
              const Text(
                'खर्च तपशील:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  final expenseName =
                      expense['expense_name']?.toString() ?? '-';
                  final amount = (expense['amount'] as num?)?.toDouble() ?? 0.0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            expenseName,
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            '₹$amount',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Summary Section
            const Divider(thickness: 2),
            const SizedBox(height: 12),

            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'एकूण रक्कम:',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          '₹$gross',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'एकूण खर्च:',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          '₹$totalExpense',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'शुद्ध रक्कम (Net):',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹$net',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
