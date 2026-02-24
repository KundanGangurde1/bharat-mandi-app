import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/firm_data_service.dart';
import '../../core/services/powersync_service.dart';
import 'pavti_detail_screen.dart';
import 'pavti_pdf_service.dart';

class PavtiListScreen extends StatefulWidget {
  const PavtiListScreen({super.key});

  @override
  State<PavtiListScreen> createState() => _PavtiListScreenState();
}

class _PavtiListScreenState extends State<PavtiListScreen> {
  List<Map<String, dynamic>> pavtis = [];
  bool isLoading = true;

  final TextEditingController _farmerSearchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadPavtis();
  }

  @override
  void dispose() {
    _farmerSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadPavtis() async {
    setState(() => isLoading = true);

    try {
      final firmId = await FirmDataService.getActiveFirmId();
      final farmerQuery = _farmerSearchController.text.trim().toLowerCase();

      String query = '''
        SELECT
          parchi_id,
          MAX(created_at) as created_at,
          farmer_name,
          farmer_code,
          SUM(total_expense) as total_expense,
          SUM(net) as net
        FROM transactions
        WHERE firm_id = ?
      ''';

      final params = <dynamic>[firmId];

      if (farmerQuery.isNotEmpty) {
        query += " AND LOWER(IFNULL(farmer_name, '')) LIKE ?";
        params.add('%$farmerQuery%');
      }

      if (_selectedDate != null) {
        final dayStart = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
        );
        final dayEnd = dayStart.add(const Duration(days: 1));
        query += ' AND created_at >= ? AND created_at < ?';
        params.add(dayStart.toIso8601String());
        params.add(dayEnd.toIso8601String());
      }

      query += '''
        GROUP BY parchi_id, farmer_name, farmer_code
        ORDER BY parchi_id DESC
      ''';

      final data = await powerSyncDB.getAll(query, params);

      setState(() {
        pavtis = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('त्रुटी: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final initialDate = _selectedDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _loadPavtis();
    }
  }

  void _clearDateFilter() {
    setState(() => _selectedDate = null);
    _loadPavtis();
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
        final firmId = await FirmDataService.getActiveFirmId();
        await powerSyncDB.execute(
          'DELETE FROM transactions WHERE firm_id = ? AND parchi_id = ?',
          [firmId, parchiId],
        );

        await _loadPavtis();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('पावती डिलीट झाली'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('त्रुटी: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadPavtiEntries(String parchiId) async {
    final firmId = await FirmDataService.getActiveFirmId();
    final entries = await powerSyncDB.getAll(
      'SELECT * FROM transactions WHERE firm_id = ? AND parchi_id = ? ORDER BY id ASC',
      [firmId, parchiId],
    );
    return entries;
  }

  Future<void> _previewPavtiPdf({
    required String parchiId,
    required String farmerName,
    required String farmerCode,
    required String formattedDate,
    required double totalExpense,
    required double net,
  }) async {
    final entries = await _loadPavtiEntries(parchiId);
    final doc = await PavtiPdfService.buildPavtiPdf(
      parchiId: parchiId,
      farmerName: farmerName,
      farmerCode: farmerCode,
      formattedDate: formattedDate,
      entries: entries,
      totalExpense: totalExpense,
      net: net,
    );

    if (!mounted) return;
    await PavtiPdfService.previewPdf(context, doc);
  }

  Future<void> _printPavtiPdf({
    required String parchiId,
    required String farmerName,
    required String farmerCode,
    required String formattedDate,
    required double totalExpense,
    required double net,
  }) async {
    final entries = await _loadPavtiEntries(parchiId);
    final doc = await PavtiPdfService.buildPavtiPdf(
      parchiId: parchiId,
      farmerName: farmerName,
      farmerCode: farmerCode,
      formattedDate: formattedDate,
      entries: entries,
      totalExpense: totalExpense,
      net: net,
    );

    await PavtiPdfService.printPdf(doc);
  }

  Future<void> _sharePavtiPdf({
    required String parchiId,
    required String farmerName,
    required String farmerCode,
    required String formattedDate,
    required double totalExpense,
    required double net,
  }) async {
    final entries = await _loadPavtiEntries(parchiId);
    final doc = await PavtiPdfService.buildPavtiPdf(
      parchiId: parchiId,
      farmerName: farmerName,
      farmerCode: farmerCode,
      formattedDate: formattedDate,
      entries: entries,
      totalExpense: totalExpense,
      net: net,
    );

    await PavtiPdfService.sharePdf(doc, parchiId);
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                TextField(
                  controller: _farmerSearchController,
                  decoration: InputDecoration(
                    labelText: 'शेतकरी नावाने शोधा',
                    hintText: 'उदा. रामराव',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _farmerSearchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _farmerSearchController.clear();
                              _loadPavtis();
                            },
                          ),
                  ),
                  onChanged: (_) => _loadPavtis(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          _selectedDate == null
                              ? 'तारीख निवडा'
                              : 'तारीख: ${DateFormat('dd-MM-yyyy').format(_selectedDate!)}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_selectedDate != null)
                      TextButton(
                        onPressed: _clearDateFilter,
                        child: const Text('क्लिअर'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
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
                              'पावती सापडली नाही',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'शोध निकष बदला आणि पुन्हा प्रयत्न करा',
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
                          final farmerName =
                              pavti['farmer_name']?.toString() ?? '';
                          final farmerCode =
                              pavti['farmer_code']?.toString() ?? '';
                          final totalExpense =
                              (pavti['total_expense'] as num?)?.toDouble() ??
                                  0.0;
                          final net = (pavti['net'] as num?)?.toDouble() ?? 0.0;

                          final parsedDate =
                              date == null ? null : DateTime.tryParse(date);
                          final formattedDate = parsedDate != null
                              ? DateFormat('dd/MM/yyyy').format(parsedDate)
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
                                        'खर्च: ₹${totalExpense.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'नेट: ₹${net.toStringAsFixed(2)}',
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
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility, size: 20),
                                        SizedBox(width: 8),
                                        Text('पाहा'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('एडिट'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'pdf_preview',
                                    child: Row(
                                      children: [
                                        Icon(Icons.picture_as_pdf, size: 20),
                                        SizedBox(width: 8),
                                        Text('PDF प्रीव्ह्यू'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'print',
                                    child: Row(
                                      children: [
                                        Icon(Icons.print, size: 20),
                                        SizedBox(width: 8),
                                        Text('प्रिंट'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'share',
                                    child: Row(
                                      children: [
                                        Icon(Icons.share, size: 20),
                                        SizedBox(width: 8),
                                        Text('PDF शेअर'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('डिलीट',
                                            style:
                                                TextStyle(color: Colors.red)),
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
                                  } else if (value == 'pdf_preview') {
                                    await _previewPavtiPdf(
                                      parchiId: parchiId,
                                      farmerName: farmerName,
                                      farmerCode: farmerCode,
                                      formattedDate: formattedDate,
                                      totalExpense: totalExpense,
                                      net: net,
                                    );
                                  } else if (value == 'print') {
                                    await _printPavtiPdf(
                                      parchiId: parchiId,
                                      farmerName: farmerName,
                                      farmerCode: farmerCode,
                                      formattedDate: formattedDate,
                                      totalExpense: totalExpense,
                                      net: net,
                                    );
                                  } else if (value == 'share') {
                                    await _sharePavtiPdf(
                                      parchiId: parchiId,
                                      farmerName: farmerName,
                                      farmerCode: farmerCode,
                                      formattedDate: formattedDate,
                                      totalExpense: totalExpense,
                                      net: net,
                                    );
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
          ),
        ],
      ),
    );
  }
}
