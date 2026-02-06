import 'package:flutter/material.dart';
import '../../core/services/powersync_service.dart';

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

  Future<void> _loadTraders() async {
    setState(() => isLoading = true);

    try {
      // PowerSync: Calculate trader recovery/receivable
      String query =
          'SELECT t.id, t.code, t.name, t.opening_balance, a.name as area_name FROM traders t LEFT JOIN areas a ON t.area_id = a.id WHERE t.active = 1';

      List<dynamic> params = [];

      if (selectedAreaId != null && selectedAreaId!.isNotEmpty) {
        query += ' AND t.area_id = ?';
        params.add(selectedAreaId);
      }

      query += ' ORDER BY t.opening_balance DESC';

      final data = await powerSyncDB.getAll(query, params);

      // Calculate receivable (opening_balance is what trader owes us)
      final tradersWithRecovery = data.map((trader) {
        final receivable =
            (trader['opening_balance'] as num?)?.toDouble() ?? 0.0;
        return {
          ...trader,
          'receivable': receivable,
        };
      }).toList();

      setState(() {
        traders = tradersWithRecovery;
        isLoading = false;
      });

      print('✅ Loaded ${traders.length} traders');
    } catch (e) {
      print("❌ Error loading trader recovery: $e");
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
            onPressed: _loadTraders,
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
                _loadTraders();
              },
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : traders.isEmpty
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
                        itemCount: traders.length,
                        itemBuilder: (context, index) {
                          final trader = traders[index];
                          final receivable =
                              (trader['receivable'] as num?)?.toDouble() ?? 0.0;
                          final traderName = trader['name']?.toString() ?? '-';
                          final traderCode = trader['code']?.toString() ?? '-';
                          final areaName =
                              trader['area_name']?.toString() ?? 'N/A';

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
                                  traderName.isNotEmpty
                                      ? traderName.substring(0, 1).toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                '$traderName ($traderCode)',
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
                                        '$traderName च्या व्यवहार तपशील (Coming Soon)'),
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
