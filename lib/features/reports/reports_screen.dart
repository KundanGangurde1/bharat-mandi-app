import 'package:flutter/material.dart';
import 'farmer_dues_report_screen.dart'; // शेतकरी थकबाकी रिपोर्ट
import 'buyer_recovery_report_screen.dart'; // खरेदीदार थकबाकी रिपोर्ट

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('अहवाल'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'उपलब्ध अहवाल',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // शेतकरी थकबाकी रिपोर्ट बटण
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.people, color: Colors.blue, size: 40),
                title: const Text('शेतकरी थकबाकी यादी'),
                subtitle: const Text('शेतकरींची देणी आणि व्यवहार यादी'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FarmerDuesReportScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // खरेदीदार थकबाकी रिपोर्ट बटण
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading:
                    const Icon(Icons.business, color: Colors.orange, size: 40),
                title: const Text('खरेदीदार घेणे यादी'),
                subtitle: const Text('खरेदीदारांची थकबाकी आणि बॅलन्स'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const BuyerRecoveryReportScreen()),
                  );
                },
              ),
            ),

            // पुढे इतर रिपोर्ट्स अॅड करशील तर इथे ठेव (उदा. एरिया wise, दैनिक इ.)
          ],
        ),
      ),
    );
  }
}
