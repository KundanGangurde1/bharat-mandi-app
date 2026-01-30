import 'package:flutter/material.dart';
import 'firm_model.dart';
import 'firm_service.dart';
import 'firm_form_screen.dart';
import 'firm_list_screen.dart';

class FirmSetupScreen extends StatefulWidget {
  const FirmSetupScreen({super.key});

  @override
  State<FirmSetupScreen> createState() => _FirmSetupScreenState();
}

class _FirmSetupScreenState extends State<FirmSetupScreen> {
  late Future<int> _firmCount;

  @override
  void initState() {
    super.initState();
    _firmCount = FirmService.getFirmCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('फर्म सेटअप'),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.deepOrange[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.deepOrange,
                      radius: 30,
                      child: const Icon(
                        Icons.business,
                        size: 35,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'फर्म व्यवस्थापन',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<int>(
                            future: _firmCount,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                  'एकूण फर्म: ${snapshot.data}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                );
                              }
                              return const Text(
                                'लोड होत आहे...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Main Options
            const Text(
              'विकल्प',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 12),

            // नवीन फर्म बनवा
            _buildOptionCard(
              icon: Icons.add_circle_outline,
              title: 'नवीन फर्म बनवा',
              subtitle: 'नवीन फर्मची माहिती जोडा',
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FirmFormScreen(),
                  ),
                ).then((_) {
                  setState(() {
                    _firmCount = FirmService.getFirmCount();
                  });
                });
              },
            ),

            const SizedBox(height: 12),

            // फर्म यादी पहा
            _buildOptionCard(
              icon: Icons.list_alt,
              title: 'फर्म यादी पहा',
              subtitle: 'सर्व फर्मची माहिती पहा',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FirmListScreen(),
                  ),
                ).then((_) {
                  setState(() {
                    _firmCount = FirmService.getFirmCount();
                  });
                });
              },
            ),

            const SizedBox(height: 12),

            // सक्रिय फर्म बदला
            _buildOptionCard(
              icon: Icons.swap_horiz,
              title: 'सक्रिय फर्म बदला',
              subtitle: 'कार्यरत फर्म निवडा',
              color: Colors.orange,
              onTap: () {
                _showActiveFirmDialog();
              },
            ),

            const SizedBox(height: 12),

            // फर्म माहिती
            _buildOptionCard(
              icon: Icons.info_outline,
              title: 'सक्रिय फर्मची माहिती',
              subtitle: 'सध्याच्या फर्मचे तपशील पहा',
              color: Colors.purple,
              onTap: () {
                _showActiveFirmDetails();
              },
            ),

            const SizedBox(height: 24),

            // Info Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'माहिती',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• आप एकाधिक फर्म तयार करू शकता\n'
                      '• प्रत्येक फर्मची स्वतंत्र माहिती ठेवा\n'
                      '• कधीही सक्रिय फर्म बदलू शकता\n'
                      '• फर्मची सर्व मुख्य माहिती संचयित करा',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActiveFirmDialog() async {
    final firms = await FirmService.getAllFirms();

    if (!mounted) return;

    if (firms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कोणताही फर्म उपलब्ध नाही'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('सक्रिय फर्म निवडा'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: firms.length,
            itemBuilder: (context, index) {
              final firm = firms[index];
              return ListTile(
                title: Text(firm.name),
                subtitle: Text(firm.owner_name),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${firm.name} सक्रिय झाले'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('रद्द करा'),
          ),
        ],
      ),
    );
  }

  void _showActiveFirmDetails() async {
    final firm = await FirmService.getActiveFirm();

    if (!mounted) return;

    if (firm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कोणताही सक्रिय फर्म नाही'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('सक्रिय फर्मची माहिती'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('फर्मचे नाव:', firm.name),
              _buildDetailRow('मालकाचे नाव:', firm.owner_name),
              _buildDetailRow('फोन:', firm.phone),
              _buildDetailRow('ईमेल:', firm.email),
              _buildDetailRow('पत्ता:', firm.address),
              _buildDetailRow('शहर:', firm.city),
              _buildDetailRow('राज्य:', firm.state),
              _buildDetailRow('पिनकोड:', firm.pincode),
              if (firm.gst_number != null && firm.gst_number!.isNotEmpty)
                _buildDetailRow('GST क्रमांक:', firm.gst_number ?? ''),
              if (firm.pan_number != null && firm.pan_number!.isNotEmpty)
                _buildDetailRow('PAN क्रमांक:', firm.pan_number ?? ''),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('बंद करा'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
