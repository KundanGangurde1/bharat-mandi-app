import 'package:flutter/material.dart';
import 'produce_form_screen.dart';
import '../../../core/services/powersync_service.dart';
import '../../../core/services/firm_data_service.dart'; // ✅ NEW

class ProduceListScreen extends StatefulWidget {
  const ProduceListScreen({super.key});

  @override
  State<ProduceListScreen> createState() => _ProduceListScreenState();
}

class _ProduceListScreenState extends State<ProduceListScreen> {
  List<Map<String, dynamic>> produceList = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProduce();
  }

  Future<void> _loadProduce() async {
    setState(() => isLoading = true);

    try {
      // ✅ NEW: Get produce for active firm only
      final data = await FirmDataService.getProduceForActiveFirm();

      setState(() {
        produceList = data;
        isLoading = false;
      });

      print('✅ Loaded ${produceList.length} produce items for active firm');
    } catch (e) {
      print("❌ Error loading produce: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटी: $e')),
        );
      }
      print('⚠️ Check if active firm is set');
    }
  }

  List<Map<String, dynamic>> get filteredProduce {
    if (searchQuery.isEmpty) return produceList;

    return produceList.where((item) {
      final name = item['name']?.toString().toLowerCase() ?? '';
      final code = item['code']?.toString().toLowerCase() ?? '';
      final variety = item['variety']?.toString().toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();

      return name.contains(query) ||
          code.contains(query) ||
          variety.contains(query);
    }).toList();
  }

  Future<void> _toggleActive(String id, bool currentStatus) async {
    try {
      // PowerSync: Toggle active status
      await updateRecord(
        'produce',
        id,
        {'active': currentStatus ? 0 : 1},
      );

      await _loadProduce();
      _showSnackBar('स्टेटस अपडेट झाला');
    } catch (e) {
      print("❌ Error updating produce: $e");
      _showSnackBar('त्रुटी: $e');
    }
  }

  Future<void> _deleteProduce(String id, String code) async {
    // PowerSync: Check if code is used in transactions
    final isUsed = await isCodeUsedInTransaction(code, 'produce');

    if (isUsed) {
      _showSnackBar('हा कोड वापरात आहे. डिलीट करू शकत नाही.');
      return;
    }

    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('पुष्टी करा'),
        content: const Text('हा माल कायमस्वरूपी डिलीट करायचा का?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('नका'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('होय'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // PowerSync: Delete produce
      await deleteRecord('produce', id);

      await _loadProduce();
      _showSnackBar('माल डिलीट झाला');
    } catch (e) {
      print("❌ Error deleting produce: $e");
      _showSnackBar('त्रुटी: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('माल व्यवस्थापन'),
        centerTitle: true,
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProduce,
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
                    produceList.length.toString(),
                    Icons.shopping_basket,
                    Colors.purple,
                  ),
                  _buildStatItem(
                    'सक्रिय',
                    produceList
                        .where((p) => p['active'] == 1)
                        .length
                        .toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatItem(
                    'निष्क्रिय',
                    produceList
                        .where((p) => p['active'] == 0)
                        .length
                        .toString(),
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
                labelText: 'माल शोधा',
                hintText: 'नाव, कोड किंवा वैरायटी टाइप करा',
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

          // Produce List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProduce.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredProduce.length,
                        itemBuilder: (context, index) {
                          final item = filteredProduce[index];
                          final isActive = item['active'] == 1;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isActive ? Colors.purple : Colors.grey,
                                child: Text(
                                  item['code']?.toString().substring(0, 1) ??
                                      '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                item['name']?.toString() ?? '',
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
                                    'कोड: ${item['code']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (item['variety'] != null &&
                                      item['variety'].toString().isNotEmpty)
                                    Text(
                                      'वैरायटी: ${item['variety']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (item['category'] != null &&
                                      item['category'].toString().isNotEmpty)
                                    Text(
                                      'श्रेणी: ${item['category']}',
                                      style: const TextStyle(fontSize: 12),
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
                                      await _toggleActive(
                                          item['id'] as String, isActive);
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
                                              ProduceFormScreen(
                                            produceId: item['id'] as String,
                                          ),
                                        ),
                                      );

                                      if (result == true) {
                                        await _loadProduce();
                                      }
                                    },
                                    tooltip: 'एडिट करा',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () async {
                                      await _deleteProduce(
                                        item['id'] as String,
                                        item['code']?.toString() ?? '',
                                      );
                                    },
                                    tooltip: 'डिलीट करा',
                                  ),
                                ],
                              ),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProduceFormScreen(
                                      produceId: item['id'] as String,
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  await _loadProduce();
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
              builder: (context) => const ProduceFormScreen(),
            ),
          );

          if (result == true) {
            await _loadProduce();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('नवीन माल'),
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
            Icons.shopping_basket_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'कोणताही माल नाही',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'पहिला माल जोडण्यासाठी + बटण वापरा',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
