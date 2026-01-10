import 'package:flutter/material.dart';
import '../../../core/services/db_service.dart';
import '../expense_type/expense_type_form_screen.dart';

class ExpenseTypeListScreen extends StatefulWidget {
  const ExpenseTypeListScreen({super.key});

  @override
  State<ExpenseTypeListScreen> createState() => _ExpenseTypeListScreenState();
}

class _ExpenseTypeListScreenState extends State<ExpenseTypeListScreen> {
  List<Map<String, dynamic>> expenseTypes = [];
  bool isLoading = true;

  // For filtering
  String selectedFilter = 'all'; // 'all', 'farmer', 'trader'

  @override
  void initState() {
    super.initState();
    _loadExpenseTypes();
  }

  Future<void> _loadExpenseTypes() async {
    setState(() => isLoading = true);

    try {
      final db = await DBService.database;
      String where = '';
      List<Object?> whereArgs = [];

      if (selectedFilter != 'all') {
        where = 'apply_on = ?';
        whereArgs.add(selectedFilter);
      }

      final data = await db.query(
        'expense_types',
        where: where.isNotEmpty ? where : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'apply_on, name ASC',
      );

      setState(() {
        expenseTypes = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading expense types: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleActive(int id, bool currentStatus) async {
    try {
      await DBService.toggleExpenseType(id, !currentStatus);
      await _loadExpenseTypes();
      _showSnackBar('स्टेटस अपडेट झाला');
    } catch (e) {
      print("Error updating expense type: $e");
      _showSnackBar('त्रुटी: $e');
    }
  }

  Future<void> _deleteExpense(int id) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('पुष्टी करा'),
        content: const Text('हे खर्च प्रकार कायमस्वरूपी डिलीट करायचे का?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('नका'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('होय'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DBService.deleteExpenseType(id);
      await _loadExpenseTypes();
      _showSnackBar('खर्च प्रकार डिलीट झाला');
    } catch (e) {
      print("Error deleting expense: $e");
      _showSnackBar('त्रुटी: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _getModeDisplay(String mode) {
    switch (mode) {
      case 'fixed':
        return '₹ (Fixed)';
      case 'percentage':
        return '% (Percentage)';
      case 'per_piece':
        return 'प्रति नग';
      case 'per_bag':
        return 'प्रति डाग';
      case 'per_weight':
        return 'प्रति वजन';
      default:
        return mode;
    }
  }

  String _getApplyOnDisplay(String applyOn) {
    return applyOn == 'farmer' ? 'किसान' : 'व्यापारी';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('खर्च प्रकार व्यवस्थापन'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenseTypes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('सर्व'),
                  selected: selectedFilter == 'all',
                  onSelected: (selected) {
                    setState(() => selectedFilter = 'all');
                    _loadExpenseTypes();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('किसान'),
                  selected: selectedFilter == 'farmer',
                  onSelected: (selected) {
                    setState(() => selectedFilter = 'farmer');
                    _loadExpenseTypes();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('व्यापारी'),
                  selected: selectedFilter == 'trader',
                  onSelected: (selected) {
                    setState(() => selectedFilter = 'trader');
                    _loadExpenseTypes();
                  },
                ),
              ],
            ),
          ),

          // Info Card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'एकूण प्रकार: ${expenseTypes.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'सक्रिय: ${expenseTypes.where((e) => e['active'] == 1).length}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
          ),

          // Expense Types List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : expenseTypes.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.money_off, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('कोणतेही खर्च प्रकार नाहीत'),
                            Text('पहिला खर्च प्रकार जोडा'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: expenseTypes.length,
                        itemBuilder: (context, index) {
                          final expense = expenseTypes[index];
                          final isActive = expense['active'] == 1;
                          final showInReport = expense['show_in_report'] == 1;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isActive ? Colors.white : Colors.grey[100],
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: expense['apply_on'] == 'farmer'
                                    ? Colors.blue
                                    : Colors.orange,
                                child: Text(
                                  expense['name']?.toString().substring(0, 1) ??
                                      '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      expense['name']?.toString() ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        decoration: isActive
                                            ? TextDecoration.none
                                            : TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                  if (!isActive)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Text(
                                        'निष्क्रिय',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(_getApplyOnDisplay(
                                            expense['apply_on'])),
                                        backgroundColor:
                                            expense['apply_on'] == 'farmer'
                                                ? Colors.blue[100]
                                                : Colors.orange[100],
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 0),
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                            _getModeDisplay(expense['mode'])),
                                        backgroundColor: Colors.green[100],
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 0),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'डिफॉल्ट: ${expense['default_value']}'
                                    '${expense['mode'] == 'percentage' ? '%' : '₹'}',
                                  ),
                                  if (!showInReport)
                                    const Text(
                                      'रिपोर्टमध्ये दिसणार नाही',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit, size: 20),
                                        const SizedBox(width: 8),
                                        const Text('एडिट'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Row(
                                      children: [
                                        Icon(
                                          isActive
                                              ? Icons.toggle_off
                                              : Icons.toggle_on,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(isActive
                                            ? 'निष्क्रिय करा'
                                            : 'सक्रिय करा'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.delete, size: 20),
                                        const SizedBox(width: 8),
                                        const Text('डिलीट'),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ExpenseTypeFormScreen(
                                          expenseId: expense['id'],
                                        ),
                                      ),
                                    );

                                    if (result == true) {
                                      await _loadExpenseTypes();
                                    }
                                  } else if (value == 'toggle') {
                                    await _toggleActive(
                                        expense['id'], isActive);
                                  } else if (value == 'delete') {
                                    await _deleteExpense(expense['id']);
                                  }
                                },
                              ),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExpenseTypeFormScreen(
                                      expenseId: expense['id'],
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  await _loadExpenseTypes();
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExpenseTypeFormScreen(),
            ),
          );

          if (result == true) {
            await _loadExpenseTypes();
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
