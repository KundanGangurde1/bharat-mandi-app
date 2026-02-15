import 'package:flutter/material.dart';
import '../../core/services/powersync_service.dart';
import '../../core/services/firm_data_service.dart'; // ✅ NEW

class FarmerDuesReportScreen extends StatefulWidget {
  const FarmerDuesReportScreen({super.key});

  @override
  State<FarmerDuesReportScreen> createState() => _FarmerDuesReportScreenState();
}

class _FarmerDuesReportScreenState extends State<FarmerDuesReportScreen> {
  List<Map<String, dynamic>> farmers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFarmerDues();
  }

  Future<void> _loadFarmerDues() async {
    setState(() => isLoading = true);

    try {
      // ✅ NEW: Calculate farmer dues for active firm
      final firmId = await FirmDataService.getActiveFirmId();
      final data = await powerSyncDB.getAll('''
        SELECT 
          f.id,
          f.code,
          f.name,
          f.phone,
          COALESCE(SUM(t.net), 0) as total_net,
          COALESCE(SUM(CASE WHEN t.net > 0 THEN t.net ELSE 0 END), 0) as dues
        FROM farmers f
        LEFT JOIN transactions t ON f.firm_id = t.firm_id AND f.code = t.farmer_code
        WHERE f.firm_id = ? AND f.active = 1
        GROUP BY f.id, f.code, f.name, f.phone
        ORDER BY dues DESC
      ''', [firmId]);

      setState(() {
        farmers = data;
        isLoading = false;
      });

      print('✅ Loaded farmer dues for ${farmers.length} farmers');
    } catch (e) {
      print('❌ Error loading farmer dues: $e');
      print('⚠️ Check if active firm is set');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटी: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('शेतकरी थकबाकी यादी'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFarmerDues,
            tooltip: 'रिफ्रेश',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : farmers.isEmpty
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
                        'सर्व शेतकरी अद्यतन आहेत',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: farmers.length,
                  itemBuilder: (context, index) {
                    final farmer = farmers[index];
                    final dues = (farmer['dues'] as num?)?.toDouble() ?? 0.0;
                    final farmerName = farmer['name']?.toString() ?? '-';
                    final farmerCode = farmer['code']?.toString() ?? '-';
                    final phone = farmer['phone']?.toString() ?? 'N/A';
                    final totalNet =
                        (farmer['total_net'] as num?)?.toDouble() ?? 0.0;

                    final isDue = dues > 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      color: isDue ? Colors.red[50] : Colors.green[50],
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDue ? Colors.red : Colors.green,
                          child: Text(
                            farmerName.isNotEmpty
                                ? farmerName.substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          '$farmerName ($farmerCode)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'फोन: $phone',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'एकूण नेट: ₹${totalNet.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${dues.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDue ? Colors.red : Colors.green,
                              ),
                            ),
                            Text(
                              isDue ? 'थकबाकी' : 'निपटलेली',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDue ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Future: Open farmer transaction details
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '$farmerName च्या व्यवहार तपशील (Coming Soon)'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
