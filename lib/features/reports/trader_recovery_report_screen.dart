import 'package:flutter/material.dart';
import '../../core/services/db_service.dart';

class TraderRecoveryReportScreen extends StatefulWidget {
  const TraderRecoveryReportScreen({super.key});

  @override
  State<TraderRecoveryReportScreen> createState() =>
      _TraderRecoveryReportScreenState();
}

class _TraderRecoveryReportScreenState
    extends State<TraderRecoveryReportScreen> {
  List<Map<String, dynamic>> traders = [];
  List<Map<String, dynamic>> areas = [];
  String? selectedAreaId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAreas();
    _loadTraders();
  }

  Future<void> _loadAreas() async {
    try {
      final db = await DBService.database;
      final data =
          await db.query('areas', where: 'active = 1', orderBy: 'name ASC');
      setState(() => areas = data);
    } catch (e) {
      print("Error loading areas: $e");
    }
  }

  Future<void> _loadTraders() async {
    setState(() => isLoading = true);
    try {
      final data = await DBService.getTraderRecovery(areaId: selectedAreaId);
      setState(() {
        traders = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading trader recovery: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('खरेदीदार थकबाकी यादी')),
      body: Column(
        children: [
          // एरिया फिल्टर
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: selectedAreaId,
              decoration: const InputDecoration(
                labelText: 'एरिया फिल्टर',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('सर्व एरिया')),
                ...areas.map((area) => DropdownMenuItem<String>(
                      value: area['id'].toString(),
                      child: Text(area['name'].toString()),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  selectedAreaId = value;
                  isLoading = true;
                });
                _loadTraders();
              },
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : traders.isEmpty
                    ? const Center(child: Text('कोणतीही थकबाकी नाही'))
                    : ListView.builder(
                        itemCount: traders.length,
                        itemBuilder: (context, index) {
                          final trader = traders[index];
                          final receivable =
                              trader['receivable'] as double? ?? 0.0;

                          return ListTile(
                            title: Text(trader['name'].toString()),
                            subtitle: Text(
                                'फर्म: ${trader['firm_name'] ?? 'N/A'} | एरिया: ${trader['area'] ?? 'N/A'}'),
                            trailing: Text(
                              '₹${receivable.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    receivable > 0 ? Colors.green : Colors.red,
                              ),
                            ),
                            onTap: () {
                              // पुढे डिटेल्स स्क्रीन बनवू
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
