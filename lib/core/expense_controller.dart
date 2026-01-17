import 'package:flutter/material.dart';
import '../core/services/db_service.dart'; // तुझ्या db_service.dart चा पाथ

class ExpenseItem {
  final int id;
  final String name;
  final String calculationType;
  final String applyOn;
  final double defaultValue;
  final TextEditingController controller = TextEditingController();

  ExpenseItem({
    required this.id,
    required this.name,
    required this.calculationType,
    required this.applyOn,
    required this.defaultValue,
  });
}

class ExpenseController extends ChangeNotifier {
  List<ExpenseItem> expenseItems = [];
  double totalExpense = 0.0;

  Future<void> loadExpenseTypes() async {
    try {
      final data = await DBService.getExpenseTypes(activeOnly: true);
      expenseItems = data
          .map((row) => ExpenseItem(
                id: row['id'] as int,
                name: row['name'] as String,
                calculationType:
                    row['calculation_type'] as String? ?? 'per_dag',
                applyOn: row['apply_on'] as String? ?? 'farmer',
                defaultValue: (row['default_value'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList();

      for (var item in expenseItems) {
        item.controller.text = item.defaultValue.toStringAsFixed(2);
        item.controller.addListener(updateTotal);
      }

      updateTotal();
      notifyListeners();
    } catch (e) {
      print("Expense load error: $e");
    }
  }

  void updateTotal() {
    double sum = 0.0;
    double totalDag = 0.0; // transaction screen ने set करेल
    double totalWeight = 0.0;
    double totalAmt = 0.0;

    for (var exp in expenseItems) {
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

  Future<void> addToTraderRecovery(String traderCode, double amount) async {
    final db = await DBService.database;
    await db.rawUpdate(
      'UPDATE traders SET opening_balance = opening_balance + ? WHERE code = ?',
      [amount, traderCode],
    );
  }
}
