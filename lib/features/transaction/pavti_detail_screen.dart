import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../core/services/powersync_service.dart';
import '../../core/services/firm_data_service.dart'; // ✅ NEW
import '../transaction/new_transaction_screen.dart';

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

  List<String> allParchiIds = [];
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // ✅ NEW: Get parchi_ids for active firm
    final firmId = await FirmDataService.getActiveFirmId();
    final ids = await powerSyncDB.getAll(
      'SELECT DISTINCT parchi_id FROM transactions WHERE firm_id = ? ORDER BY parchi_id ASC',
      [firmId],
    );

    allParchiIds = ids.map((e) => e['parchi_id'].toString()).toList();

    currentIndex = allParchiIds.indexOf(widget.parchiId);

    await _loadPavtiDetails();
  }

  Future<void> _loadPavtiDetails() async {
    setState(() => isLoading = true);

    try {
      // ✅ NEW: Load transactions for active firm
      final firmId = await FirmDataService.getActiveFirmId();
      final data = await powerSyncDB.getAll(
        'SELECT * FROM transactions WHERE firm_id = ? AND parchi_id = ? ORDER BY id ASC',
        [firmId, widget.parchiId],
      );

      final expenseData = await powerSyncDB.getAll(
        'SELECT te.*, et.name as expense_name FROM transaction_expenses te '
        'LEFT JOIN expense_types et ON te.expense_type_id = et.id '
        'WHERE te.firm_id = ? AND te.parchi_id = ?',
        [firmId, widget.parchiId],
      );

      setState(() {
        entries = data;
        expenses = expenseData;
        pavti = data.isNotEmpty ? data.first : {};
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading pavti: $e');
      print('⚠️ Check if active firm is set');
      setState(() => isLoading = false);
    }
  }

  void _goPrevious() {
    if (currentIndex > 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PavtiDetailScreen(
            parchiId: allParchiIds[currentIndex - 1],
          ),
        ),
      );
    }
  }

  void _goNext() {
    if (currentIndex < allParchiIds.length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PavtiDetailScreen(
            parchiId: allParchiIds[currentIndex + 1],
          ),
        ),
      );
    }
  }

  double _calculateGross() {
    double total = 0;
    for (final e in entries) {
      total += (e['gross'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  double _calculateExpense() {
    double total = 0;
    for (final e in expenses) {
      total += (e['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('पावती तपशील'),
          backgroundColor: Colors.green,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (entries.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('पावती तपशील'),
          backgroundColor: Colors.green,
        ),
        body: const Center(child: Text('पावती उपलब्ध नाही')),
      );
    }

    final farmerName = pavti['farmer_name'] ?? '-';
    final farmerCode = pavti['farmer_code'] ?? '-';
    final createdAt = pavti['created_at'];
    final formattedDate = createdAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(createdAt))
        : '-';

    final gross = _calculateGross();
    final totalExpense = _calculateExpense();
    final net = gross - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('पावती तपशील'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewTransactionScreen(
                    parchiId: widget.parchiId,
                    isEdit: true,
                  ),
                ),
              );
              _loadPavtiDetails();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // HEADER
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('पावती नं: ${widget.parchiId}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('शेतकरी: $farmerName ($farmerCode)'),
                    Text('तारीख: $formattedDate'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ENTRIES
            ...entries.map((e) {
              final buyer = e['buyer_name'];
              final produce = e['produce_name'];
              final qty = e['quantity'];
              final rate = e['rate'];
              final gross = e['gross'];

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text('$buyer - $produce'),
                  subtitle: Text('वजन: $qty × ₹$rate'),
                  trailing: Text('₹$gross'),
                ),
              );
            }),

            const Divider(thickness: 2),

            // SUMMARY
            ListTile(
              title: const Text('एकूण रक्कम'),
              trailing: Text('₹${gross.toStringAsFixed(2)}'),
            ),
            ListTile(
              title: const Text('एकूण खर्च'),
              trailing: Text('₹${totalExpense.toStringAsFixed(2)}'),
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'शुद्ध रक्कम',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                '₹${net.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),

            const SizedBox(height: 20),

            // NAVIGATION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _goPrevious,
                  child: const Text('← मागील'),
                ),
                ElevatedButton(
                  onPressed: _goNext,
                  child: const Text('पुढील →'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
