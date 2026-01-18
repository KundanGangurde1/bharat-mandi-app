import 'package:flutter/material.dart';
import '../../../core/services/db_service.dart';

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
      final db = await DBService.database;
      final data = await db.query(
        'areas',
        where: 'active = 1',
        orderBy: 'name ASC',
      );
      setState(() {
        areas = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading areas: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _addOrEditArea(
      {int? id, required String name, bool active = true}) async {
    final db = await DBService.database;
    final now = DateTime.now().toIso8601String();

    if (id == null) {
      await db.insert('areas', {
        'name': name,
        'active': active ? 1 : 0,
        'created_at': now,
        'updated_at': now,
      });
    } else {
      await db.update(
        'areas',
        {
          'name': name,
          'active': active ? 1 : 0,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    _loadAreas();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(id == null ? 'एरिया जोडला गेला' : 'एरिया अपडेट झाला')),
    );
  }

  Future<void> _deleteArea(int id) async {
    final db = await DBService.database;
    await db.delete('areas', where: 'id = ?', whereArgs: [id]);
    _loadAreas();
  }

  void _showFormDialog({int? id, String? initialName}) {
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
                child: const Text('रद्द करा')),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  _addOrEditArea(
                      id: id, name: nameCtrl.text.trim(), active: active);
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
      appBar: AppBar(title: const Text('एरिया मास्टर')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: areas.length,
              itemBuilder: (context, index) {
                final area = areas[index];
                return ListTile(
                  title: Text(area['name'].toString()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showFormDialog(
                            id: area['id'],
                            initialName: area['name'].toString()),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteArea(area['id'] as int),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
