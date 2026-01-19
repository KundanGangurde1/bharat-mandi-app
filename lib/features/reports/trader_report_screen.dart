import 'package:flutter/material.dart';
import '../../core/services/db_service.dart';

class TraderReportScreen extends StatefulWidget {
  const TraderReportScreen({super.key});

  @override
  State<TraderReportScreen> createState() => _TraderReportScreenState();
}

class _TraderReportScreenState extends State<TraderReportScreen> {
  List<Map<String, dynamic>> traders = [];
  List<Map<String, dynamic>> areas = [];
  String? selectedAreaId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final db = await DBService.database;

      // Areas लोड कर (फिल्टर साठी)
      final areaData =
          await db.query('areas', where: 'active = 1', orderBy: 'name ASC');
      setState(() => areas = areaData);

      // Traders लोड कर (एरिया फिल्टर लागू कर)
      String query =
          'SELECT t.*, COALESCE(t.opening_balance, 0) as balance FROM traders t';
      List<Object?> args = [];

      if (selectedAreaId != null) {
        query += ' WHERE t.area_id = ?';
        args.add(selectedAreaId);
      }

      query += ' ORDER BY t.name ASC';

      final traderData = await db.rawQuery(query, args);

      setState(() {
        traders = traderData;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading trader report: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('खरेदीदार घेणे यादी'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // एरिया फिल्टर Dropdown
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    value: selectedAreaId,
                    decoration: const InputDecoration(
                      labelText: 'एरिया फिल्टर',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('सर्व एरिया')),
                      ...areas.map((area) {
                        return DropdownMenuItem<String>(
                          value: area['id'].toString(),
                          child: Text(area['name'].toString()),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedAreaId = value;
                        isLoading = true;
                      });
                      _loadData();
                    },
                  ),
                ),

                // Trader List
                Expanded(
                  child: traders.isEmpty
                      ? const Center(child: Text('कोणताही खरेदीदार नाही'))
                      : ListView.builder(
                          itemCount: traders.length,
                          itemBuilder: (context, index) {
                            final trader = traders[index];
                            final balance = trader['balance'] as double? ?? 0.0;

                            return ListTile(
                              title: Text(trader['name'].toString()),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('फर्म: ${trader['firm_name'] ?? 'N/A'}'),
                                  Text('एरिया: ${trader['area'] ?? 'N/A'}'),
                                  Text('फोन: ${trader['phone'] ?? 'N/A'}'),
                                ],
                              ),
                              trailing: Text(
                                '₹${balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      balance > 0 ? Colors.green : Colors.red,
                                ),
                              ),
                              onTap: () {
                                // पुढे डिटेल्स स्क्रीन बनवू (transactions list)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          '${trader['name']} ची माहिती लवकरच येईल')),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
