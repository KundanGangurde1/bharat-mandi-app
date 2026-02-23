import 'package:flutter/material.dart';
import '../../core/services/powersync_service.dart';
import '../../core/services/firm_data_service.dart';
import '../buyer/buyer_ledger_screen.dart';

class BuyerRecoveryReportScreen extends StatefulWidget {
  const BuyerRecoveryReportScreen({super.key});

  @override
  State<BuyerRecoveryReportScreen> createState() =>
      _BuyerRecoveryReportScreenState();
}

class _BuyerRecoveryReportScreenState extends State<BuyerRecoveryReportScreen> {
  List<Map<String, dynamic>> buyers = [];
  bool isLoading = true;
  String partyCodeFilter = '';

  @override
  void initState() {
    super.initState();
    _loadBuyers();
  }

  Future<void> _loadBuyers() async {
    setState(() => isLoading = true);

    try {
      final firmId = await FirmDataService.getActiveFirmId();
      final data = await getBuyerRecovery(firmId: firmId);

      setState(() {
        buyers = data;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading buyer recovery: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBuyers = buyers.where((b) {
      if (partyCodeFilter.isEmpty) return true;
      final code = (b['code']?.toString() ?? '').toUpperCase();
      return code.contains(partyCodeFilter);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('खातेउतारा'),
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
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'पार्टी कोडने शोधा',
                hintText: 'उदा. B001',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                setState(() {
                  partyCodeFilter = value.trim().toUpperCase();
                });
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBuyers.isEmpty
                    ? const Center(child: Text('नोंदी उपलब्ध नाहीत'))
                    : ListView.builder(
                        itemCount: filteredBuyers.length,
                        itemBuilder: (context, index) {
                          final b = filteredBuyers[index];
                          final balance =
                              (b['balance'] as num?)?.toDouble() ?? 0.0;

                          return Card(
                            child: ListTile(
                              title: Text('${b['name']} (${b['code']})'),
                              subtitle: const Text('तपशील/प्रिंट/PDF/शेअर'),
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
