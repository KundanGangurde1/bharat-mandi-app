import 'package:flutter/material.dart';
import 'buyer_recovery_report_screen.dart';
import 'udhari_report_screen.dart';
import 'sales_report_screen.dart';
import 'cash_receipt_report_screen.dart';

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
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.receipt_long,
                    color: Colors.orange, size: 40),
                title: const Text('खातेउतारा'),
                subtitle: const Text(
                    'पार्टीनुसार व्यवहार तपशील, प्रिंट/PDF/शेअर सुविधा'),
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
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading:
                    const Icon(Icons.list_alt, color: Colors.blue, size: 40),
                title: const Text('उधारी यादी'),
                subtitle: const Text(
                    'एरिया/पार्टी/दिनांक फिल्टरसह उधारी, PDF/प्रिंट/शेअर'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UdhariReportScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading:
                    const Icon(Icons.bar_chart, color: Colors.purple, size: 40),
                title: const Text('विक्री रिपोर्ट'),
                subtitle: const Text(
                    'दिनांकानुसार विक्री, खर्च आणि निव्वळ रक्कम PDF/प्रिंट/शेअर'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SalesReportScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading:
                    const Icon(Icons.payments, color: Colors.teal, size: 40),
                title: const Text('कॅश रिसीट'),
                subtitle: const Text(
                    'पार्टीनुसार तारीखदरम्यान खाते जमा/रोख जमा आणि बाकी रिपोर्ट'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CashReceiptReportScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
