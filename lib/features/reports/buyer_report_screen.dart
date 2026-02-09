import 'package:flutter/material.dart';
import '../../core/services/powersync_service.dart';

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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      // PowerSync: Load areas for filter
      final areaData = await powerSyncDB.getAll(
        'SELECT * FROM areas WHERE active = 1 ORDER BY name ASC',
      );

      setState(() => areas = areaData);
      print('✅ Loaded ${areas.length} areas');

      // PowerSync: Load buyers with optional area filter
      String query =
          'SELECT t.id, t.code, t.name, t.phone, t.opening_balance as balance, a.name as area_name FROM buyers t LEFT JOIN areas a ON t.area_id = a.id WHERE t.active = 1';

      List<dynamic> args = [];

      if (selectedAreaId != null && selectedAreaId!.isNotEmpty) {
        query += ' AND t.area_id = ?';
        args.add(selectedAreaId);
      }

      query += ' ORDER BY t.name ASC';

      final buyerData = await powerSyncDB.getAll(query, args);

      setState(() {
        buyers = buyerData;
        isLoading = false;
      });

      print('✅ Loaded ${buyers.length} buyers');
    } catch (e) {
      print("❌ Error loading buyer report: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('खरेदीदार यादी लोड करण्यात त्रुटी: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('खरेदीदार घेणे यादी'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'रिफ्रेश',
          ),
        ],
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
                      prefixIcon: Icon(Icons.location_on),
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

                // buyer List
                Expanded(
                  child: buyers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'कोणताही खरेदीदार नाही',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: buyers.length,
                          itemBuilder: (context, index) {
                            final buyer = buyers[index];
                            final balance =
                                (buyer['balance'] as num?)?.toDouble() ?? 0.0;
                            final buyerName = buyer['name']?.toString() ?? '-';
                            final buyerCode = buyer['code']?.toString() ?? '-';
                            final phone = buyer['phone']?.toString() ?? 'N/A';
                            final areaName =
                                buyer['area_name']?.toString() ?? 'N/A';

                            final isPositive = balance > 0;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              color: isPositive
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      isPositive ? Colors.green : Colors.red,
                                  child: Text(
                                    buyerName.isNotEmpty
                                        ? buyerName
                                            .substring(0, 1)
                                            .toUpperCase()
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
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'एरिया: $areaName',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'फोन: $phone',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${balance.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isPositive
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    Text(
                                      isPositive ? 'प्राप्य' : 'देय',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isPositive
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
