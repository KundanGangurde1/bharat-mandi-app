import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/firm_data_service.dart';
import '../../core/services/powersync_service.dart';
import '../../core/utils/pdf_font_helper.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  bool isLoading = true;
  DateTime? fromDate;
  DateTime? toDate;
  List<Map<String, dynamic>> rows = [];

  double totalQty = 0.0;
  double totalGross = 0.0;
  double totalExpense = 0.0;
  double totalNet = 0.0;

  @override
  void initState() {
    super.initState();
    // Set default dates: today
    final now = DateTime.now();
    fromDate = now;
    toDate = now;
    _loadReport();
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => fromDate = picked);
      await _loadReport();
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => toDate = picked);
      await _loadReport();
    }
  }

  Future<void> _loadReport() async {
    setState(() => isLoading = true);

    try {
      final firmId = await FirmDataService.getActiveFirmId();
      if (firmId == null) throw Exception('कोणताही सक्रिय फर्म नाही');

      if (fromDate == null || toDate == null) {
        throw Exception('कृपया तारीख निवडा');
      }

      // Ensure fromDate <= toDate
      DateTime start = fromDate!;
      DateTime end = toDate!;
      if (start.isAfter(end)) {
        final temp = start;
        start = end;
        end = temp;
      }

      // Add 1 day to end to include all transactions on that day
      final endPlusOne = end.add(const Duration(days: 1));

      final data = await powerSyncDB.getAll(
        '''SELECT
             buyer_code,
             buyer_name,
             produce_name,
             quantity,
             rate,
             gross,
             total_expense,
             farmer_expense,
             net,
             created_at
           FROM transactions
           WHERE firm_id = ? AND created_at >= ? AND created_at < ?
           ORDER BY buyer_name ASC, created_at ASC''',
        [firmId, start.toIso8601String(), endPlusOne.toIso8601String()],
      );

      double qty = 0, gross = 0, exp = 0, net = 0;
      for (final r in data) {
        final q = (r['quantity'] as num?)?.toDouble() ?? 0.0;
        final g = (r['gross'] as num?)?.toDouble() ?? 0.0;
        final be = (r['total_expense'] as num?)?.toDouble() ?? 0.0;
        final fe = (r['farmer_expense'] as num?)?.toDouble() ?? 0.0;
        final n = (r['net'] as num?)?.toDouble() ?? 0.0;

        qty += q;
        gross += g;
        exp += (be + fe);
        net += n;
      }

      setState(() {
        rows = data;
        totalQty = qty;
        totalGross = gross;
        totalExpense = exp;
        totalNet = net;
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'निवडा';
    return DateFormat('dd-MM-yyyy').format(date);
  }

  Future<pw.Document> _buildPdf() async {
    final regularFont = await PdfFontHelper.regular();
    final boldFont = await PdfFontHelper.bold();
    final pdf = pw.Document();

    final dateRange = fromDate == toDate
        ? _formatDate(fromDate)
        : '${_formatDate(fromDate)} ते ${_formatDate(toDate)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('विक्री रिपोर्ट',
              style: pw.TextStyle(font: boldFont, fontSize: 18)),
          pw.SizedBox(height: 4),
          pw.Text('दिनांक: $dateRange', style: pw.TextStyle(font: regularFont)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(font: boldFont),
            cellStyle: pw.TextStyle(font: regularFont),
            headers: const [
              'पार्टी',
              'माल',
              'प्रमाण',
              'दर',
              'एकूण',
              'खर्च',
              'निव्वळ'
            ],
            data: rows.map((r) {
              final be = (r['total_expense'] as num?)?.toDouble() ?? 0.0;
              final fe = (r['farmer_expense'] as num?)?.toDouble() ?? 0.0;
              return [
                (r['buyer_name'] ?? '').toString(),
                (r['produce_name'] ?? '').toString(),
                ((r['quantity'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
                ((r['rate'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
                ((r['gross'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
                (be + fe).toStringAsFixed(2),
                ((r['net'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 10),
          pw.Text('एकूण प्रमाण: ${totalQty.toStringAsFixed(2)}',
              style: pw.TextStyle(font: regularFont)),
          pw.Text('एकूण विक्री: ₹${totalGross.toStringAsFixed(2)}',
              style: pw.TextStyle(font: regularFont)),
          pw.Text('एकूण खर्च: ₹${totalExpense.toStringAsFixed(2)}',
              style: pw.TextStyle(font: regularFont)),
          pw.Text('एकूण निव्वळ: ₹${totalNet.toStringAsFixed(2)}',
              style: pw.TextStyle(font: boldFont)),
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
        '${dir.path}/vikri_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'विक्री रिपोर्ट');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('विक्री रिपोर्ट'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReport),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: rows.isEmpty ? null : _printPreview,
            tooltip: 'प्रिंट/PDF प्रीव्ह्यू',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: rows.isEmpty ? null : _sharePdf,
            tooltip: 'PDF शेअर',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromDate,
                    icon: const Icon(Icons.date_range),
                    label: Text('From: ${_formatDate(fromDate)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickToDate,
                    icon: const Icon(Icons.date_range),
                    label: Text('To: ${_formatDate(toDate)}'),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: rows.isEmpty
                  ? const Center(
                      child: Text('निवडलेल्या कालावधीत विक्री नोंद नाही'))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'एकूण प्रमाण: ${totalQty.toStringAsFixed(2)}'),
                                  Text(
                                      'एकूण विक्री: ₹${totalGross.toStringAsFixed(2)}'),
                                  Text(
                                      'एकूण खर्च: ₹${totalExpense.toStringAsFixed(2)}'),
                                  Text(
                                      'एकूण निव्वळ: ₹${totalNet.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: rows.length,
                            itemBuilder: (context, index) {
                              final r = rows[index];
                              final be =
                                  (r['total_expense'] as num?)?.toDouble() ??
                                      0.0;
                              final fe =
                                  (r['farmer_expense'] as num?)?.toDouble() ??
                                      0.0;
                              final expense = be + fe;

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                child: ListTile(
                                  title: Text(
                                      '${r['buyer_name']} (${r['buyer_code']}) - ${r['produce_name']}'),
                                  subtitle: Text(
                                      'प्रमाण: ${((r['quantity'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)} | दर: ₹${((r['rate'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}'),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                          'एकूण: ₹${((r['gross'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}'),
                                      Text(
                                          'खर्च: ₹${expense.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              color: Colors.deepOrange,
                                              fontWeight: FontWeight.w600)),
                                      Text(
                                          'निव्वळ: ₹${((r['net'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}'),
                                    ],
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
