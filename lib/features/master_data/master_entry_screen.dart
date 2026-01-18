import 'package:flutter/material.dart';
import 'area/area_master_screen.dart';
import 'farmer/farmer_list_screen.dart';
import 'trader/trader_list_screen.dart';
import 'produce/produce_list_screen.dart';
import 'expense_type/expense_type_list_screen.dart';

class MasterEntryScreen extends StatelessWidget {
  const MasterEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('मास्टर एन्ट्री'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMasterCard(
              icon: Icons.people,
              title: 'शेतकरी',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FarmerListScreen())),
            ),
            _buildMasterCard(
              icon: Icons.business,
              title: 'खरेदीदार',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TraderListScreen())),
            ),
            _buildMasterCard(
              icon: Icons.inventory,
              title: 'माल',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProduceListScreen())),
            ),
            _buildMasterCard(
              icon: Icons.money_off,
              title: 'खर्च प्रकार',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ExpenseTypeListScreen())),
            ),
            _buildMasterCard(
              icon: Icons.location_city,
              title: 'एरिया',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AreaMasterScreen())),
            ),
            // पुढे इतर मास्टर्स अॅड करशील तर इथे ठेव
          ],
        ),
      ),
    );
  }

  Widget _buildMasterCard(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.green),
            const SizedBox(height: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
