import 'package:flutter/material.dart';
import '../core/services/powersync_service.dart';

class ExpenseItem {
  final String id;
  final String name;
  final String calculationType;
  final String applyOn;
  final double defaultValue;
  final double commission; // ✅ NEW: Commission field
  final TextEditingController controller = TextEditingController();

  ExpenseItem({
    required this.id,
    required this.name,
    required this.calculationType,
    required this.applyOn,
    required this.defaultValue,
    this.commission = 0.0, // ✅ NEW: Default commission
  });
}

class ExpenseController extends ChangeNotifier {
  List<ExpenseItem> expenseItems = [];
  double totalExpense = 0.0;

  Future<void> loadExpenseTypes() async {
    try {
      // PowerSync: Load active expense types
      final data = await powerSyncDB.getAll(
        'SELECT * FROM expense_types WHERE active = 1 ORDER BY name ASC',
      );

      expenseItems = data
          .map((row) => ExpenseItem(
                id: row['id'] as String,
                name: row['name'] as String,
                calculationType:
                    row['calculation_type'] as String? ?? 'per_dag',
                applyOn: row['apply_on'] as String? ?? 'farmer',
                defaultValue: (row['default_value'] as num?)?.toDouble() ?? 0.0,
                commission:
                    (row['commission'] as num?)?.toDouble() ?? 0.0, // ✅ NEW
              ))
          .toList();

      for (var item in expenseItems) {
        item.controller.text = item.defaultValue.toStringAsFixed(2);
        item.controller.addListener(updateTotal);
      }

      updateTotal();
      notifyListeners();

      print('✅ Loaded ${expenseItems.length} expense types');
    } catch (e) {
      print("❌ Expense load error: $e");
    }
  }

  void updateTotal([double totalDag = 0.0, double totalAmt = 0.0]) {
    // optional arguments
    double sum = 0.0;

    for (var exp in expenseItems) {
      // ✅ SKIP: "कमिशन" expense (handled in transaction logic via TAP A/TAP B)
      if (exp.name.trim() == 'कमिशन') {
        print(
            '⏭️ Skipping कमिशन expense in updateTotal (handled via TAP logic)');
        continue;
      }

      if (exp.applyOn != 'farmer') continue;

      final entered = double.tryParse(exp.controller.text) ?? exp.defaultValue;
      if (entered <= 0) continue;

      double calculated = 0.0;
      switch (exp.calculationType) {
        case 'per_dag':
          calculated = totalDag * entered;
          break;
        case 'percentage':
          calculated = totalAmt * (entered / 100);
          break;
        case 'fixed':
          calculated = entered;
          break;
      }
      sum += calculated;
    }

    totalExpense = sum;
    notifyListeners();
  }

  Future<void> addToBuyerRecovery(String buyerCode, double amount) async {
    try {
      // PowerSync: Update buyer opening balance
      await powerSyncDB.execute(
        'UPDATE buyers SET opening_balance = opening_balance + ? WHERE code = ?',
        [amount, buyerCode],
      );

      print('✅ Updated buyer recovery for $buyerCode: +$amount');
    } catch (e) {
      print("❌ Error updating buyer recovery: $e");
    }
  }
}
