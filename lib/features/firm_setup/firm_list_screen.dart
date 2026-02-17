import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firm_model.dart';
import 'firm_service.dart';
import 'firm_form_screen.dart';
import '../../core/active_firm_provider.dart';

class FirmListScreen extends StatefulWidget {
  const FirmListScreen({super.key});

  @override
  State<FirmListScreen> createState() => _FirmListScreenState();
}

class _FirmListScreenState extends State<FirmListScreen> {
  late Future<List<Firm>> _firmsFuture;

  @override
  void initState() {
    super.initState();
    _firmsFuture = FirmService.getAllFirms();
  }

  void _refreshList() {
    setState(() {
      _firmsFuture = FirmService.getAllFirms();
    });
  }

  void _showDeleteDialog(Firm firm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('फर्म हटवा'),
        content: Text('क्या ${firm.name} हटवायचे आहे?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('रद्द करा'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Convert id to String for PowerSync
                await FirmService.deleteFirm(firm.id.toString());
                _refreshList();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('फर्म हटवला गेला'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('त्रुटी: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('हटवा'),
          ),
        ],
      ),
    );
  }

  void _showFirmDetails(Firm firm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(firm.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('मालक:', firm.owner_name),
              _buildDetailRow('फोन:', firm.phone),
              _buildDetailRow('ईमेल:', firm.email),
              _buildDetailRow('पत्ता:', firm.address),
              _buildDetailRow('शहर:', firm.city),
              _buildDetailRow('राज्य:', firm.state),
              _buildDetailRow('पिनकोड:', firm.pincode),
              if (firm.gst_number != null && firm.gst_number!.isNotEmpty)
                _buildDetailRow('GST:', firm.gst_number ?? ''),
              if (firm.pan_number != null && firm.pan_number!.isNotEmpty)
                _buildDetailRow('PAN:', firm.pan_number ?? ''),
              _buildDetailRow(
                'तयार केले:',
                firm.created_at.split('T')[0],
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('फर्म यादी'),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshList,
          ),
        ],
      ),
      body: FutureBuilder<List<Firm>>(
        future: _firmsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('त्रुटी: ${snapshot.error}'),
            );
          }

          final firms = snapshot.data ?? [];

          if (firms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_center,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'कोणताही फर्म नाही',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FirmFormScreen(),
                        ),
                      ).then((_) => _refreshList());
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('नवीन फर्म जोडा'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: firms.length,
            itemBuilder: (context, index) {
              final firm = firms[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepOrange[100],
                    child: Icon(
                      Icons.business,
                      color: Colors.deepOrange,
                    ),
                  ),
                  title: Text(
                    firm.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${firm.owner_name} • ${firm.city}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 20),
                            SizedBox(width: 8),
                            Text('तपशील'),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(Duration.zero, () {
                            _showFirmDetails(firm);
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('संपादित करा'),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(Duration.zero, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FirmFormScreen(firm: firm),
                              ),
                            ).then((_) => _refreshList());
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 20,
                              color: firm.active ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              firm.active ? 'सक्रिय (Active)' : 'सक्रिय करा',
                              style: TextStyle(
                                color:
                                    firm.active ? Colors.green : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        onTap: firm.active
                            ? null
                            : () {
                                Future.delayed(Duration.zero, () async {
                                  try {
                                    final provider =
                                        Provider.of<ActiveFirmProvider>(context,
                                            listen: false);
                                    await provider.setActiveFirm(firm);

                                    if (!mounted) return;

                                    Navigator.pop(
                                        context); // Close FirmListScreen

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('${firm.name} सक्रिय झाले'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('त्रुटी: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                });
                              },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('हटवा', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(Duration.zero, () {
                            _showDeleteDialog(firm);
                          });
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    _showFirmDetails(firm);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FirmFormScreen(),
            ),
          ).then((_) => _refreshList());
        },
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.add),
        label: const Text('नवीन फर्म'),
      ),
    );
  }
}
