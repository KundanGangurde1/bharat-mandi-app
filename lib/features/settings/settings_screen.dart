import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('सेटिंग्ज'),
        centerTitle: true,
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Settings
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.language, color: Colors.blue),
                  title: Text('भाषा'),
                  subtitle: Text('मराठी, हिंदी, इंग्रजी'),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
                Divider(height: 1, color: Colors.grey[300]),
                const ListTile(
                  leading: Icon(Icons.palette, color: Colors.green),
                  title: Text('थीम'),
                  subtitle: Text('रंग संयोजन बदला'),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Data Management
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.backup, color: Colors.orange),
                  title: Text('बॅकअप'),
                  subtitle: Text('डेटा बॅकअप घ्या'),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
                Divider(height: 1, color: Colors.grey[300]),
                const ListTile(
                  leading: Icon(Icons.restore, color: Colors.purple),
                  title: Text('पुनर्संचयित'),
                  subtitle: Text('बॅकअपवरून डेटा परत आणा'),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // App Info
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info, color: Colors.teal),
                  title: Text('अ‍ॅप बद्दल'),
                  subtitle: Text('आवृत्ती आणि माहिती'),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
                Divider(height: 1, color: Colors.grey[300]),
                const ListTile(
                  leading: Icon(Icons.help, color: Colors.blueGrey),
                  title: Text('मदत'),
                  subtitle: Text('वापर कसा करायचा'),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
                Divider(height: 1, color: Colors.grey[300]),
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.indigo),
                  title: const Text('शेअर करा'),
                  subtitle: const Text('अ‍ॅप इतरांसोबत शेअर करा'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('शेअर फंक्शनलिटी लवकरच येईल')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Reset Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('पुष्टी करा'),
                    content:
                        const Text('सर्व सेटिंग्ज रीसेट करायच्या आहेत का?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('रद्द करा'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('सेटिंग्ज रीसेट झाल्या'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('रीसेट करा'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text('सेटिंग्ज रीसेट करा'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
