import 'package:flutter/material.dart';
import '../../core/services/powersync_service.dart';

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
      // PowerSync: Load active areas
      final data = await powerSyncDB.getAll(
        'SELECT * FROM areas WHERE active = 1 ORDER BY name ASC',
      );

      setState(() => areas = data);
      print('✅ Loaded ${areas.length} areas');
    } catch (e) {
      print("❌ Error loading areas: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('एरिया लोड करण्यात त्रुटी: $e')),
        );
      }
    }
  }

  Future<void> _loadBuyers() async {
    setState(() => isLoading = true);

    try {
      // PowerSync: Calculate buyer recovery/receivable
      String query =
          'SELECT t.id, t.code, t.name, t.opening_balance, a.name as area_name FROM buyers t LEFT JOIN areas a ON t.area_id = a.id WHERE t.active = 1';

      List<dynamic> params = [];

      if (selectedAreaId != null && selectedAreaId!.isNotEmpty) {
        query += ' AND t.area_id = ?';
        params.add(selectedAreaId);
      }

      query += ' ORDER BY t.opening_balance DESC';

      final data = await powerSyncDB.getAll(query, params);

      // Calculate receivable (opening_balance is what buyer owes us)
      final buyersWithRecovery = data.map((buyer) {
        final receivable =
            (buyer['opening_balance'] as num?)?.toDouble() ?? 0.0;
        return {
          ...buyer,
          'receivable': receivable,
        };
      }).toList();

      setState(() {
        buyers = buyersWithRecovery;
        isLoading = false;
      });

      print('✅ Loaded ${buyers.length} buyers');
    } catch (e) {
      print("❌ Error loading buyer recovery: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('खरेदीदार थकबाकी लोड करण्यात त्रुटी: $e')),
        );
      }
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
            tooltip: 'रिफ्रेश',
          ),
        ],
      ),
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
                prefixIcon: Icon(Icons.location_on),
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
                _loadBuyers();
              },
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : buyers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 80,
                              color: Colors.green[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'कोणतीही थकबाकी नाही',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'सर्व खरेदीदार अद्यतन आहेत',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: buyers.length,
                        itemBuilder: (context, index) {
                          final buyer = buyers[index];
                          final receivable =
                              (buyer['receivable'] as num?)?.toDouble() ?? 0.0;
                          final buyerName = buyer['name']?.toString() ?? '-';
                          final buyerCode = buyer['code']?.toString() ?? '-';
                          final areaName =
                              buyer['area_name']?.toString() ?? 'N/A';

                          final isReceivable = receivable > 0;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 2,
                            color: isReceivable
                                ? Colors.green[50]
                                : Colors.red[50],
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isReceivable ? Colors.green : Colors.red,
                                child: Text(
                                  buyerName.isNotEmpty
                                      ? buyerName.substring(0, 1).toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                '$buyerName ($buyerCode)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                'एरिया: $areaName',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${receivable.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isReceivable
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  Text(
                                    isReceivable ? 'प्राप्य' : 'देय',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isReceivable
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '$buyerName च्या व्यवहार तपशील (Coming Soon)'),
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
