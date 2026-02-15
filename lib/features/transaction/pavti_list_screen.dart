import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../core/services/powersync_service.dart';
import '../../core/services/firm_data_service.dart'; // ✅ NEW
import 'pavti_detail_screen.dart';

class PavtiListScreen extends StatefulWidget {
  const PavtiListScreen({super.key});

  @override
  State<PavtiListScreen> createState() => _PavtiListScreenState();
}

class _PavtiListScreenState extends State<PavtiListScreen> {
  List<Map<String, dynamic>> pavtis = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPavtis();
  }

  Future<void> _loadPavtis() async {
    setState(() => isLoading = true);

    try {
      // ✅ NEW: Get distinct transactions for active firm
      final firmId = await FirmDataService.getActiveFirmId();
      final data = await powerSyncDB.getAll('''
  SELECT 
    parchi_id,
    MAX(created_at) as created_at,
    farmer_name,
    farmer_code,
    SUM(total_expense) as total_expense,
    SUM(net) as net
  FROM transactions
  WHERE firm_id = ?
  GROUP BY parchi_id, farmer_name, farmer_code
  ORDER BY parchi_id DESC
''', [firmId]);

      setState(() {
        pavtis = data;
        isLoading = false;
      });

      print('✅ Loaded ${pavtis.length} pavtis');
    } catch (e) {
      print("❌ Error loading pavtis: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटी: $e')),
        );
      }
    }
  }

  Future<void> _deletePavti(String parchiId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('पावती डिलीट करा'),
        content: const Text('खरंच ही पावती डिलीट करायची आहे का?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('नाही'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('होय'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // ✅ NEW: Delete transactions for active firm
        final firmId = await FirmDataService.getActiveFirmId();
        await powerSyncDB.execute(
          'DELETE FROM transactions WHERE firm_id = ? AND parchi_id = ?',
          [firmId, parchiId],
        );

        await _loadPavtis();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('पावती डिलीट झाली'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('❌ Error deleting pavti: $e');
        print('⚠️ Check if active firm is set');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('त्रुटी: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('पावती यादी'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPavtis,
            tooltip: 'रिफ्रेश',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pavtis.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'कोणतीही पावती नाही',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'नवीन पावती जोडण्यासाठी होम स्क्रीनवर जा',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: pavtis.length,
                  itemBuilder: (context, index) {
                    final pavti = pavtis[index];
                    final date = pavti['created_at'] as String?;
                    final parchiId = pavti['parchi_id']?.toString() ?? '';
                    final farmerName = pavti['farmer_name']?.toString() ?? '';
                    final farmerCode = pavti['farmer_code']?.toString() ?? '';
                    final totalExpense =
                        (pavti['total_expense'] as num?)?.toDouble() ?? 0.0;
                    final net = (pavti['net'] as num?)?.toDouble() ?? 0.0;

                    final formattedDate = date != null
                        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(date))
                        : '-';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text(
                            parchiId.isNotEmpty
                                ? parchiId.substring(0, 1)
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          'पावती नं: $parchiId',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'शेतकरी: $farmerName ($farmerCode)',
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              'तारीख: $formattedDate',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Row(
                              children: [
                                Text(
                                  'खर्च: ₹$totalExpense',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'नेट: ₹$net',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: const [
                                  Icon(Icons.visibility, size: 20),
                                  SizedBox(width: 8),
                                  Text('पाहा'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: const [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('एडिट'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: const [
                                  Icon(Icons.delete,
                                      size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('डिलीट',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'view' || value == 'edit') {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PavtiDetailScreen(
                                    parchiId: parchiId,
                                    isEdit: value == 'edit',
                                  ),
                                ),
                              );
                              await _loadPavtis();
                            } else if (value == 'delete') {
                              await _deletePavti(parchiId);
                            }
                          },
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PavtiDetailScreen(
                                parchiId: parchiId,
                                isEdit: false,
                              ),
                            ),
                          );
                          await _loadPavtis();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
