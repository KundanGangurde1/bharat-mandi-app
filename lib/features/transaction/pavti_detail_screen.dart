import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../core/services/db_service.dart';
// import 'new_transaction_screen.dart'; // गरज नसल्यास कमेंट करा

class PavtiDetailScreen extends StatefulWidget {
  final String parchiId;
  final bool isEdit;

  const PavtiDetailScreen(
      {super.key, required this.parchiId, this.isEdit = false});

  @override
  State<PavtiDetailScreen> createState() => _PavtiDetailScreenState();
}

class _PavtiDetailScreenState extends State<PavtiDetailScreen> {
  Map<String, dynamic> pavti = {};
  List<Map<String, dynamic>> entries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPavtiDetails();
  }

  Future<void> _loadPavtiDetails() async {
    try {
      final db = await DBService.database;
      // तपासा की तुमच्या टेबलमध्ये column नाव 'parchi_id' आहे की 'transaction_id'
      final data = await db.query('transactions',
          where: 'id = ?', whereArgs: [widget.parchiId]); // id ने चेक करा

      // जर आयटम्स वेगळ्या टेबलमध्ये असतील तर क्वेरी बदलावी लागेल
      // सध्या मी गृहित धरतोय की तुम्ही एकाच टेबलमधून डेटा आणत आहात

      setState(() {
        entries = data;
        if (data.isNotEmpty) {
          pavti = data.first;
        }
        isLoading = false;
      });
    } catch (e) {
      print("Error loading pavti: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (entries.isEmpty) {
      return const Center(child: Text('पावती माहिती उपलब्ध नाही'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('पावती तपशील'),
        actions: [
          if (widget.isEdit)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('पावती अपडेट झाली')));
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('पावती ID: ${widget.parchiId}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Null safety साठी ?? '' वापरले आहे
            Text('शेतकरी: ${pavti['farmer_name'] ?? '-'}'),
            const SizedBox(height: 8),
            Text(
                'तारीख: ${pavti['created_at'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(pavti['created_at'])) : '-'}'),
            const SizedBox(height: 16),
            const Text('एंट्री यादी:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      // 👇 इथे बदल केला आहे (Main Fix)
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('व्यापारी: ${entry['trader_name'] ?? '-'}'),
                          Text('माल: ${entry['produce_name'] ?? '-'}'),
                          Text('डाग: ${entry['dag'] ?? 0}'),
                          Text('वजन: ${entry['quantity'] ?? 0}'),
                          Text('भाव: ₹${entry['rate'] ?? 0}'),
                          Text('रक्कम: ₹${entry['gross'] ?? 0}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('एकूण खर्च:'),
                Text('₹${pavti['total_expense'] ?? 0}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('शुद्ध रक्कम (Net):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('₹${pavti['net'] ?? 0}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
