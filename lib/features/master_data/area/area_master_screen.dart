import 'package:flutter/material.dart';
import '../../../core/services/powersync_service.dart';

class AreaMasterScreen extends StatefulWidget {
  const AreaMasterScreen({super.key});

  @override
  State<AreaMasterScreen> createState() => _AreaMasterScreenState();
}

class _AreaMasterScreenState extends State<AreaMasterScreen> {
  List<Map<String, dynamic>> areas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    try {
      // PowerSync: Load active areas ordered by name
      final data = await powerSyncDB.getAll(
        'SELECT * FROM areas WHERE active = 1 ORDER BY name ASC',
      );

      setState(() {
        areas = data;
        isLoading = false;
      });

      print('✅ Loaded ${areas.length} areas');
    } catch (e) {
      print("❌ Error loading areas: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटी: $e')),
        );
      }
    }
  }

  Future<void> _addOrEditArea(
      {String? id, required String name, bool active = true}) async {
    final now = DateTime.now().toIso8601String();

    try {
      if (id == null) {
        // PowerSync: Insert new area
        await insertRecord('areas', {
          'name': name,
          'active': active ? 1 : 0,
          'created_at': now,
          'updated_at': now,
        });
      } else {
        // PowerSync: Update existing area
        await updateRecord('areas', id, {
          'name': name,
          'active': active ? 1 : 0,
          'updated_at': now,
        });
      }

      await _loadAreas();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(id == null ? 'एरिया जोडला गेला' : 'एरिया अपडेट झाला'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("❌ Error saving area: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('त्रुटी: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteArea(String id) async {
    try {
      // PowerSync: Delete area
      await deleteRecord('areas', id);
      await _loadAreas();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('एरिया डिलीट झाला'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("❌ Error deleting area: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('त्रुटी: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFormDialog({String? id, String? initialName}) {
    final nameCtrl = TextEditingController(text: initialName ?? '');
    bool active = true;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(id == null ? 'नवीन एरिया' : 'एरिया एडिट करा'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'एरिया नाव'),
              ),
              SwitchListTile(
                title: const Text('सक्रिय'),
                value: active,
                onChanged: (v) => setState(() => active = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('रद्द करा'),
            ),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  _addOrEditArea(
                    id: id,
                    name: nameCtrl.text.trim(),
                    active: active,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('जतन करा'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('एरिया मास्टर'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAreas,
            tooltip: 'रिफ्रेश',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : areas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_city_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'कोणतेही एरिया नाहीत',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'पहिला एरिया जोडण्यासाठी + बटण वापरा',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: areas.length,
                  itemBuilder: (context, index) {
                    final area = areas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Text(
                            area['name']
                                    ?.toString()
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          area['name']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showFormDialog(
                                id: area['id'] as String,
                                initialName: area['name']?.toString(),
                              ),
                              tooltip: 'एडिट करा',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('पुष्टी करा'),
                                    content: const Text(
                                        'हा एरिया कायमस्वरूपी डिलीट करायचा का?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('नका'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('होय'),
                                      ),
                                    ],
                                  ),
                                ).then((confirmed) {
                                  if (confirmed == true) {
                                    _deleteArea(area['id'] as String);
                                  }
                                });
                              },
                              tooltip: 'डिलीट करा',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
