import 'package:flutter/material.dart';
import '../transaction/new_transaction_screen.dart';
import '../master_data/master_entry_screen.dart'; // नवीन मास्टर एन्ट्री स्क्रीन
import '../reports/reports_screen.dart'; // अहवाल स्क्रीन (पुढे बनवू)
import '../settings/settings_screen.dart';
import '../transaction/pavti_list_screen.dart';
import '../firm_setup/firm_setup_screen.dart';
import '../recovery/payment_entry_screen.dart'; // ✅ जमा एन्ट्री स्क्रीन
import '../recovery/daily_payment_report_screen.dart'; // ✅ आज का जमा रिपोर्ट
import '../recovery/payment_list_screen.dart'; // ✅ जमा यादी

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
        appBar: AppBar(
          title: const Text('डॅशबोर्ड'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.green),
                child: const Text(
                  'भारत मंडी',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('डॅशबोर्ड'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt),
                title: const Text('नवीन पावती'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NewTransactionScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text('जमा एन्ट्री'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PaymentEntryScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('आज का जमा रिपोर्ट'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DailyPaymentReportScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('जमा यादी'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PaymentListScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('मास्टर एन्ट्री'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MasterEntryScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.assessment),
                title: const Text('अहवाल'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ReportsScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('पावती यादी'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PavtiListScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.business_center),
                title: const Text('फर्म सेटअप'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FirmSetupScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'त्वरित क्रिया',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: isMobile ? 2 : 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildQuickActionCard(
                      icon: Icons.receipt,
                      title: 'नवीन पावती',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NewTransactionScreen()),
                      ),
                    ),
                    _buildQuickActionCard(
                      icon: Icons.payment,
                      title: 'जमा एन्ट्री',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PaymentEntryScreen()),
                      ),
                    ),
                    _buildQuickActionCard(
                      icon: Icons.bar_chart,
                      title: 'आज का जमा',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const DailyPaymentReportScreen()),
                      ),
                    ),
                    _buildQuickActionCard(
                      icon: Icons.category,
                      title: 'मास्टर एन्ट्री',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MasterEntryScreen()),
                      ),
                    ),
                    _buildQuickActionCard(
                      icon: Icons.assessment,
                      title: 'अहवाल',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ReportsScreen()),
                      ),
                    ),
                    _buildQuickActionCard(
                      icon: Icons.list,
                      title: 'पावती यादी',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PavtiListScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // तुझ्या जुन्या डॅशबोर्ड कार्ड्स (आजचा सारांश) – तसेच ठेवले
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('आजचा सारांश',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('एकूण पावत्या:'),
                            const Text('१२',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('एकूण रक्कम:'),
                            const Text('₹१,२५,०००',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('थकबाकी:'),
                            const Text('₹१५,०००',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
