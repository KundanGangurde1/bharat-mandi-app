import 'package:flutter/material.dart';
import '../../core/services/powersync_service.dart';
import '../buyer/buyer_ledger_screen.dart';

class BuyerReportScreen extends StatefulWidget {
  const BuyerReportScreen({super.key});

  @override
  State<BuyerReportScreen> createState() => _BuyerReportScreenState();
}

class _BuyerReportScreenState extends State<BuyerReportScreen> {
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
    final data = await powerSyncDB.getAll(
      'SELECT * FROM areas WHERE active = 1 ORDER BY name ASC',
    );
    setState(() => areas = data);
  }

  Future<void> _loadBuyers() async {
    setState(() => isLoading = true);

    final data = await getBuyerRecovery(areaId: selectedAreaId);

    setState(() {
      buyers = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('खरेदीदार यादी'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
                : ListView.builder(
                    itemCount: buyers.length,
                    itemBuilder: (context, index) {
                      final b = buyers[index];
                      final balance = (b['balance'] as num?)?.toDouble() ?? 0.0;

                      return ListTile(
                        title: Text('${b['name']} (${b['code']})'),
                        trailing: Text(
                          '₹${balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: balance >= 0 ? Colors.green : Colors.red,
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
