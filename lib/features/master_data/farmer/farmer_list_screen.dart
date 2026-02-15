import 'package:flutter/material.dart';
import 'farmer_form_screen.dart';
import '../../../core/services/powersync_service.dart';
import '../../../core/services/firm_data_service.dart'; // ✅ NEW

class FarmerListScreen extends StatefulWidget {
  const FarmerListScreen({super.key});

  @override
  State<FarmerListScreen> createState() => _FarmerListScreenState();
}

class _FarmerListScreenState extends State<FarmerListScreen> {
  List<Map<String, dynamic>> farmers = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  Future<void> _loadFarmers() async {
    setState(() => isLoading = true);

    try {
      // ✅ NEW: Get farmers for active firm only
      final data = await FirmDataService.getFarmersForActiveFirm();

      setState(() {
        farmers = data;
        isLoading = false;
      });

      print('✅ Loaded ${farmers.length} farmers for active firm');
    } catch (e) {
      print("❌ Error loading farmers: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटी: $e')),
        );
      }
      print('⚠️ Check if active firm is set');
    }
  }

  List<Map<String, dynamic>> get filteredFarmers {
    if (searchQuery.isEmpty) return farmers;

    return farmers.where((farmer) {
      final name = farmer['name']?.toString().toLowerCase() ?? '';
      final code = farmer['code']?.toString().toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();

      return name.contains(query) || code.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('शेतकरी व्यवस्थापन'),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFarmers,
            tooltip: 'रिफ्रेश',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Card with Stats
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'एकूण',
                    farmers.length.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                  _buildStatItem(
                    'सक्रिय',
                    farmers.where((f) => f['active'] == 1).length.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatItem(
                    'निष्क्रिय',
                    farmers.where((f) => f['active'] == 0).length.toString(),
                    Icons.remove_circle,
                    Colors.red,
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'शेतकरी शोधा',
                hintText: 'नाव किंवा कोड टाइप करा',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // Farmers List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredFarmers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredFarmers.length,
                        itemBuilder: (context, index) {
                          final farmer = filteredFarmers[index];
                          final isActive = farmer['active'] == 1;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isActive ? Colors.blue : Colors.grey,
                                child: Text(
                                  farmer['code']?.toString().substring(0, 1) ??
                                      '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                farmer['name']?.toString() ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: isActive
                                      ? TextDecoration.none
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'कोड: ${farmer['code']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (farmer['phone'] != null &&
                                      farmer['phone'].toString().isNotEmpty)
                                    Text(
                                      'फोन: ${farmer['phone']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (farmer['opening_balance'] != 0)
                                    Text(
                                      'बॅलन्स: ₹${farmer['opening_balance']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            (farmer['opening_balance'] ?? 0) > 0
                                                ? Colors.red
                                                : Colors.green,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isActive
                                          ? Icons.toggle_on
                                          : Icons.toggle_off,
                                      color:
                                          isActive ? Colors.green : Colors.grey,
                                    ),
                                    onPressed: () async {
                                      // PowerSync: Toggle active status
                                      try {
                                        await updateRecord(
                                          'farmers',
                                          farmer['id'] as String,
                                          {'active': isActive ? 0 : 1},
                                        );
                                        await _loadFarmers();
                                      } catch (e) {
                                        print("❌ Error toggling farmer: $e");
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text('त्रुटी: $e'),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    tooltip: isActive
                                        ? 'निष्क्रिय करा'
                                        : 'सक्रिय करा',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              FarmerFormScreen(
                                            farmerId: farmer['id'] as String,
                                          ),
                                        ),
                                      );

                                      if (result == true) {
                                        await _loadFarmers();
                                      }
                                    },
                                    tooltip: 'एडिट करा',
                                  ),
                                ],
                              ),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FarmerFormScreen(
                                      farmerId: farmer['id'] as String,
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  await _loadFarmers();
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FarmerFormScreen(),
            ),
          );

          if (result == true) {
            await _loadFarmers();
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('नवीन शेतकरी'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'कोणतेही शेतकरी नाहीत',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'पहिला शेतकरी जोडण्यासाठी + बटण वापरा',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
