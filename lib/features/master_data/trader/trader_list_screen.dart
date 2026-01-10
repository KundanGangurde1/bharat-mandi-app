import 'package:flutter/material.dart';
import 'trader_form_screen.dart';
import '../../../core/services/db_service.dart';

class TraderListScreen extends StatefulWidget {
  const TraderListScreen({super.key});

  @override
  State<TraderListScreen> createState() => _TraderListScreenState();
}

class _TraderListScreenState extends State<TraderListScreen> {
  List<Map<String, dynamic>> traders = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTraders();
  }

  Future<void> _loadTraders() async {
    setState(() => isLoading = true);

    try {
      final db = await DBService.database;
      final data = await db.query(
        'traders',
        orderBy: 'name ASC',
      );

      setState(() {
        traders = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading traders: $e");
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredTraders {
    if (searchQuery.isEmpty) return traders;

    return traders.where((trader) {
      final name = trader['name']?.toString().toLowerCase() ?? '';
      final code = trader['code']?.toString().toLowerCase() ?? '';
      final firm = trader['firm_name']?.toString().toLowerCase() ?? '';
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
            onPressed: _loadTraders,
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
                    traders.length.toString(),
                    Icons.business,
                    Colors.orange,
                  ),
                  _buildStatItem(
                    'सक्रिय',
                    traders.where((t) => t['active'] == 1).length.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatItem(
                    'निष्क्रिय',
                    traders.where((t) => t['active'] == 0).length.toString(),
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

          // Traders List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTraders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredTraders.length,
                        itemBuilder: (context, index) {
                          final trader = filteredTraders[index];
                          final isActive = trader['active'] == 1;

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
                                  trader['code']?.toString().substring(0, 1) ??
                                      '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                trader['name']?.toString() ?? '',
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
                                    'कोड: ${trader['code']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (trader['firm_name'] != null &&
                                      trader['firm_name'].toString().isNotEmpty)
                                    Text(
                                      'फर्म: ${trader['firm_name']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (trader['area'] != null &&
                                      trader['area'].toString().isNotEmpty)
                                    Text(
                                      'क्षेत्र: ${trader['area']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (trader['opening_balance'] != 0)
                                    Text(
                                      'बॅलन्स: ₹${trader['opening_balance']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            (trader['opening_balance'] ?? 0) > 0
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
                                      try {
                                        final db = await DBService.database;
                                        await db.update(
                                          'traders',
                                          {'active': isActive ? 0 : 1},
                                          where: 'id = ?',
                                          whereArgs: [trader['id']],
                                        );
                                        await _loadTraders();
                                      } catch (e) {
                                        print("Error toggling trader: $e");
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
                                      // Edit trader
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TraderFormScreen(
                                            traderId: trader['id'],
                                          ),
                                        ),
                                      );

                                      if (result == true) {
                                        await _loadTraders();
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
                                    builder: (context) => TraderFormScreen(
                                      traderId: trader['id'],
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  await _loadTraders();
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
              builder: (context) => const TraderFormScreen(),
            ),
          );

          if (result == true) {
            await _loadTraders();
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
