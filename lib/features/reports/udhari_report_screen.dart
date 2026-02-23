import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/firm_data_service.dart';
import '../../core/services/powersync_service.dart';

class UdhariReportScreen extends StatefulWidget {
  const UdhariReportScreen({super.key});

  @override
  State<UdhariReportScreen> createState() => _UdhariReportScreenState();
}

class _UdhariReportScreenState extends State<UdhariReportScreen> {
  bool isLoading = true;

  List<Map<String, dynamic>> areas = [];
  List<Map<String, dynamic>> buyers = [];
  List<Map<String, dynamic>> reportRows = [];

  String? selectedAreaId;
  String? selectedBuyerCode;
  DateTime asOfDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadFiltersAndReport();
  }

  Future<void> _pickAsOfDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: asOfDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => asOfDate = picked);
      await _loadReport();
    }
  }

  Future<void> _loadFiltersAndReport() async {
    try {
      final firmId = await FirmDataService.getActiveFirmId();
      if (firmId == null) throw Exception('कोणताही सक्रिय फर्म नाही');

      final areaRows = await powerSyncDB.getAll(
        'SELECT id, name FROM areas WHERE firm_id = ? AND active = 1 ORDER BY name ASC',
        [firmId],
      );

      final buyerRows = await powerSyncDB.getAll(
        'SELECT code, name FROM buyers WHERE firm_id = ? AND active = 1 ORDER BY name ASC',
        [firmId],
      );

      setState(() {
        areas = areaRows;
        buyers = buyerRows;
      });

      await _loadReport();
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('त्रुटी: $e')));
      }
    }
  }

  Future<void> _loadReport() async {
    setState(() => isLoading = true);

    try {
      final firmId = await FirmDataService.getActiveFirmId();
      if (firmId == null) throw Exception('कोणताही सक्रिय फर्म नाही');

      final endExclusive = DateTime(
        asOfDate.year,
        asOfDate.month,
        asOfDate.day,
      ).add(const Duration(days: 1)).toIso8601String();

      String query = '''
        SELECT
          b.code,
          b.name,
          a.name AS area_name,
          (
            IFNULL(b.opening_balance, 0)
            + IFNULL((
                SELECT SUM(CAST(t.net AS REAL))
                FROM transactions t
                WHERE t.firm_id = b.firm_id
                  AND t.buyer_code = b.code
                  AND t.created_at < ?
              ), 0)
            - IFNULL((
                SELECT SUM(CAST(p.amount AS REAL))
                FROM payments p
                WHERE p.firm_id = b.firm_id
                  AND p.buyer_code = b.code
                  AND p.created_at < ?
              ), 0)
          ) AS balance
        FROM buyers b
        LEFT JOIN areas a ON a.id = b.area_id
        WHERE b.firm_id = ? AND b.active = 1
      ''';

      final params = <dynamic>[endExclusive, endExclusive, firmId];

      if (selectedAreaId != null && selectedAreaId!.isNotEmpty) {
        query += ' AND b.area_id = ?';
        params.add(selectedAreaId);
      }

      if (selectedBuyerCode != null && selectedBuyerCode!.isNotEmpty) {
        query += ' AND b.code = ?';
        params.add(selectedBuyerCode);
      }

      query += ' ORDER BY b.name ASC';

      final rows = await powerSyncDB.getAll(query, params);

      setState(() {
        reportRows = rows;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('त्रुटी: $e')));
      }
    }
  }

  Future<pw.Document> _buildPdf() async {
    final pdf = pw.Document();

    final total = reportRows.fold<double>(
      0,
      (sum, row) => sum + ((row['balance'] as num?)?.toDouble() ?? 0.0),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('उधारी यादी',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text(
              'दिनांक: ${asOfDate.year}-${asOfDate.month.toString().padLeft(2, '0')}-${asOfDate.day.toString().padLeft(2, '0')}'),
          pw.SizedBox(height: 6),
          pw.Text(
              'एरिया: ${selectedAreaId == null ? 'सर्व' : areas.firstWhere((a) => a['id'].toString() == selectedAreaId, orElse: () => {
                    'name': '-'
                  })['name']}'),
          pw.Text(
              'पार्टी: ${selectedBuyerCode == null ? 'सर्व' : selectedBuyerCode}'),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: const ['कोड', 'नाव', 'एरिया', 'उधारी'],
            data: reportRows.map((r) {
              final bal = (r['balance'] as num?)?.toDouble() ?? 0.0;
              return [
                (r['code'] ?? '').toString(),
                (r['name'] ?? '').toString(),
                (r['area_name'] ?? '-').toString(),
                bal.toStringAsFixed(2),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 8),
          pw.Text('एकूण उधारी: ₹${total.toStringAsFixed(2)}',
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        ],
      ),
    );

    return pdf;
  }

  Future<void> _printPreview() async {
    final pdf = await _buildPdf();
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _sharePdf() async {
    final pdf = await _buildPdf();
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/udhari_yadi_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'उधारी यादी');
  }

  @override
  Widget build(BuildContext context) {
    final total = reportRows.fold<double>(
      0,
      (sum, row) => sum + ((row['balance'] as num?)?.toDouble() ?? 0.0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('उधारी यादी'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: reportRows.isEmpty ? null : _printPreview,
            tooltip: 'प्रिंट/PDF प्रीव्ह्यू',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: reportRows.isEmpty ? null : _sharePdf,
            tooltip: 'PDF शेअर',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedAreaId,
                        decoration: const InputDecoration(
                          labelText: 'एरिया फिल्टर',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('सर्व एरिया')),
                          ...areas.map((a) => DropdownMenuItem(
                                value: a['id'].toString(),
                                child: Text(a['name'].toString()),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => selectedAreaId = value);
                          _loadReport();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedBuyerCode,
                        decoration: const InputDecoration(
                          labelText: 'पार्टी फिल्टर',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('सर्व पार्टी')),
                          ...buyers.map((b) => DropdownMenuItem(
                                value: b['code'].toString(),
                                child: Text('${b['name']} (${b['code']})'),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => selectedBuyerCode = value);
                          _loadReport();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickAsOfDate,
                        icon: const Icon(Icons.date_range),
                        label: Text(
                            'दिनांक: ${asOfDate.year}-${asOfDate.month.toString().padLeft(2, '0')}-${asOfDate.day.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: reportRows.isEmpty
                  ? const Center(child: Text('नोंदी उपलब्ध नाहीत'))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Card(
                            child: ListTile(
                              title: const Text('एकूण उधारी'),
                              trailing: Text(
                                '₹${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: reportRows.length,
                            itemBuilder: (context, index) {
                              final row = reportRows[index];
                              final balance =
                                  (row['balance'] as num?)?.toDouble() ?? 0.0;
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                child: ListTile(
                                  title:
                                      Text('${row['name']} (${row['code']})'),
                                  subtitle:
                                      Text('एरिया: ${row['area_name'] ?? '-'}'),
                                  trailing: Text(
                                    '₹${balance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: balance >= 0
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}
