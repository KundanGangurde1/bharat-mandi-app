import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../core/services/db_service.dart';
import 'pavti_detail_screen.dart'; // व्ह्यू/एडिट साठी

class PavtiListScreen extends StatefulWidget {
  const PavtiListScreen({super.key});

  @override
  State<PavtiListScreen> createState() => _PavtiListScreenState();
}

class _PavtiListScreenState extends State<PavtiListScreen> {
  List<Map<String, dynamic>> pavtis = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPavtis();
  }

  Future<void> _loadPavtis() async {
    try {
      final db = await DBService.database;
      final data = await db.rawQuery('''
        SELECT DISTINCT parchi_id, created_at, farmer_name, total_expense, net
        FROM transactions
        ORDER BY created_at DESC
      ''');
      setState(() {
        pavtis = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading pavtis: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _deletePavti(String parchiId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('पावती डिलीट करा'),
        content: const Text('खरंच ही पावती डिलीट करायची आहे का?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('नाही')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('होय')),
        ],
      ),
    );

    if (confirm == true) {
      await DBService.deletePavti(parchiId);
      _loadPavtis();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('पावती डिलीट झाली')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('पावती यादी')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pavtis.isEmpty
              ? const Center(child: Text('कोणतीही पावती नाही'))
              : ListView.builder(
                  itemCount: pavtis.length,
                  itemBuilder: (context, index) {
                    final pavti = pavtis[index];
                    final date = pavti['created_at'] as String;

                    return ListTile(
                      title: Text('पावती ID: ${pavti['parchi_id']}'),
                      subtitle: Text(
                        'शेतकरी: ${pavti['farmer_name']} | तारीख: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(date))}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PavtiDetailScreen(
                                    parchiId: pavti['parchi_id'].toString(),
                                    isEdit: false),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PavtiDetailScreen(
                                    parchiId: pavti['parchi_id'].toString(),
                                    isEdit: true),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                _deletePavti(pavti['parchi_id'].toString()),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
