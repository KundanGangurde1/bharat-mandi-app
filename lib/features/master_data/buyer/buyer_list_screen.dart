import 'package:flutter/material.dart';
import 'buyer_form_screen.dart';
import '../../../core/services/powersync_service.dart';
import '../../../core/services/firm_data_service.dart'; // ✅ NEW

class BuyerListScreen extends StatefulWidget {
  const BuyerListScreen({super.key});

  @override
  State<BuyerListScreen> createState() => _BuyerListScreenState();
}

class _BuyerListScreenState extends State<BuyerListScreen> {
  List<Map<String, dynamic>> buyers = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBuyers();
  }

  Future<void> _loadBuyers() async {
    setState(() => isLoading = true);

    try {
      // ✅ NEW: Get buyers for active firm only
      final data = await FirmDataService.getBuyersForActiveFirm();

      setState(() {
        buyers = data;
        isLoading = false;
      });

      print('✅ Loaded ${buyers.length} buyers for active firm');
    } catch (e) {
      print("❌ Error loading buyers: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटी: $e')),
        );
      }
      print('⚠️ Check if active firm is set');
    }
  }

  List<Map<String, dynamic>> get filteredBuyers {
    if (searchQuery.isEmpty) return buyers;

    return buyers.where((buyer) {
      final name = buyer['name']?.toString().toLowerCase() ?? '';
      final code = buyer['code']?.toString().toLowerCase() ?? '';
      final firm = buyer['firm_name']?.toString().toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();

      return name.contains(query) ||
          code.contains(query) ||
          firm.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('व्यापारी व्यवस्थापन'),
        centerTitle: true,
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 4,
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
                    buyers.length.toString(),
                    Icons.business,
                    Colors.orange,
                  ),
                  _buildStatItem(
                    'सक्रिय',
                    buyers.where((t) => t['active'] == 1).length.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatItem(
                    'निष्क्रिय',
                    buyers.where((t) => t['active'] == 0).length.toString(),
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
                labelText: 'व्यापारी शोधा',
                hintText: 'नाव, कोड किंवा फर्म टाइप करा',
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

          // buyers List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBuyers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredBuyers.length,
                        itemBuilder: (context, index) {
                          final buyer = filteredBuyers[index];
                          final isActive = buyer['active'] == 1;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isActive ? Colors.orange : Colors.grey,
                                child: Text(
                                  buyer['code']?.toString().substring(0, 1) ??
                                      '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                buyer['name']?.toString() ?? '',
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
                                    'कोड: ${buyer['code']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (buyer['firm_name'] != null &&
                                      buyer['firm_name'].toString().isNotEmpty)
                                    Text(
                                      'फर्म: ${buyer['firm_name']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (buyer['area'] != null &&
                                      buyer['area'].toString().isNotEmpty)
                                    Text(
                                      'क्षेत्र: ${buyer['area']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (buyer['opening_balance'] != 0)
                                    Text(
                                      'बॅलन्स: ₹${buyer['opening_balance']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            (buyer['opening_balance'] ?? 0) > 0
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
                                          'buyers',
                                          buyer['id'] as String,
                                          {'active': isActive ? 0 : 1},
                                        );
                                        await _loadBuyers();
                                      } catch (e) {
                                        print("❌ Error toggling buyer: $e");
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
                                          builder: (context) => BuyerFormScreen(
                                            buyerId: buyer['id'] as String,
                                          ),
                                        ),
                                      );

                                      if (result == true) {
                                        await _loadBuyers();
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
                                    builder: (context) => BuyerFormScreen(
                                      buyerId: buyer['id'] as String,
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  await _loadBuyers();
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
              builder: (context) => const BuyerFormScreen(),
            ),
          );

          if (result == true) {
            await _loadBuyers();
          }
        },
        icon: const Icon(Icons.business_center),
        label: const Text('नवीन व्यापारी'),
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
            color: color.withOpacity(0.1),
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
            Icons.business_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'कोणतेही व्यापारी नाहीत',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'पहिला व्यापारी जोडण्यासाठी + बटण वापरा',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
