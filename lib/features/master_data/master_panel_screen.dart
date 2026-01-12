import 'package:flutter/material.dart';

import 'farmer/farmer_list_screen.dart';
import 'trader/trader_list_screen.dart';
import 'produce/produce_list_screen.dart';
import 'expense_type/expense_type_list_screen.dart';

class MasterPanelScreen extends StatelessWidget {
  const MasterPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Master Data")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _tile(context, "🧑‍🌾 Farmers", const FarmerListScreen()),
            _tile(context, "💼 Traders", const TraderListScreen()),
            _tile(context, "🌾 Produce", const ProduceListScreen()),
            _tile(context, "💸 Expenses", const ExpenseListScreen()),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String title, Widget screen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
          },
          child: Text(title),
        ),
      ),
    );
  }
}
