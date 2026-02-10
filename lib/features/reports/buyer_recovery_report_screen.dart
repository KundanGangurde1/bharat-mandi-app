import 'package:flutter/material.dart';
import '../../core/services/powersync_service.dart';
import '../buyer/buyer_ledger_screen.dart';

class BuyerRecoveryReportScreen extends StatefulWidget {
  const BuyerRecoveryReportScreen({super.key});

  @override
  State<BuyerRecoveryReportScreen> createState() =>
      _BuyerRecoveryReportScreenState();
}

class _BuyerRecoveryReportScreenState extends State<BuyerRecoveryReportScreen> {
  List<Map<String, dynamic>> buyers = [];
  List<Map<String, dynamic>> areas = [];
  String? selectedAreaId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAreas();
    _loadBuyers();
  }

  Future<void> _loadAreas() async {
    try {
      final data = await powerSyncDB.getAll(
        'SELECT * FROM areas WHERE active = 1 ORDER BY name ASC',
      );
      setState(() => areas = data);
    } catch (e) {
      print("❌ Error loading areas: $e");
    }
  }

  Future<void> _loadBuyers() async {
    setState(() => isLoading = true);

    try {
      final data = await getBuyerRecovery(areaId: selectedAreaId);

      setState(() {
        buyers = data;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error loading buyer recovery: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('खरेदीदार थकबाकी यादी'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBuyers,
          ),
        ],
      ),
      body: Column(
        children: [
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
                ...areas.map((a) => DropdownMenuItem(
                      value: a['id'].toString(),
                      child: Text(a['name'].toString()),
                    )),
              ],
              onChanged: (value) {
                selectedAreaId = value;
                _loadBuyers();
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : buyers.isEmpty
                    ? const Center(child: Text('कोणतीही थकबाकी नाही'))
                    : ListView.builder(
                        itemCount: buyers.length,
                        itemBuilder: (context, index) {
                          final b = buyers[index];
                          final balance =
                              (b['balance'] as num?)?.toDouble() ?? 0.0;

                          return Card(
                            child: ListTile(
                              title: Text('${b['name']} (${b['code']})'),
                              subtitle: Text('एरिया: ${b['area_name'] ?? '-'}'),
                              trailing: Text(
                                '₹${balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      balance >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BuyerLedgerScreen(
                                      buyerCode: b['code'],
                                      buyerName: b['name'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
