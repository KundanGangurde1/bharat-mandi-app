import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/utils/pdf_font_helper.dart';

class BuyerLedgerPdf {
  static Future<pw.Document> _buildPdf({
    required String firmName,
    required String buyerName,
    required String buyerCode,
    DateTime? fromDate,
    DateTime? toDate,
    required List<Map<String, dynamic>> ledger,
  }) async {
    final pdf = pw.Document();

    final font = await PdfFontHelper.regular();

    double totalUdhari = 0.0;
    double totalJama = 0.0;

    for (final row in ledger) {
      totalUdhari += (row['udhari'] as double? ?? 0.0);
      totalJama += (row['jama'] as double? ?? 0.0);
    }

    final headers = [
      'दिनांक',
      'तपशील',
      'संदर्भ',
      'उधारी',
      'जमा',
      'शिल्लक',
    ];

    final data = ledger.map((row) {
      return [
        row['date'] == null
            ? '-'
            : DateFormat('dd/MM/yyyy').format(DateTime.parse(row['date'])),
        row['type'],
        row['ref'].toString(),
        row['udhari'] > 0 ? row['udhari'].toStringAsFixed(2) : '',
        row['jama'] > 0 ? row['jama'].toStringAsFixed(2) : '',
        row['balance'].toStringAsFixed(2),
      ];
    }).toList();

    // Add total row
    data.add([
      '',
      'एकूण',
      '',
      totalUdhari.toStringAsFixed(2),
      totalJama.toStringAsFixed(2),
      '',
    ]);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            firmName,
            style: pw.TextStyle(
              font: font,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'खरेदीदार: $buyerName ($buyerCode)',
            style: pw.TextStyle(font: font),
          ),
          pw.Text(
            'कालावधी: '
            '${fromDate != null ? DateFormat('dd/MM/yyyy').format(fromDate) : '-'}'
            ' ते '
            '${toDate != null ? DateFormat('dd/MM/yyyy').format(toDate) : '-'}',
            style: pw.TextStyle(font: font),
          ),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            border: pw.TableBorder.all(),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(
              font: font,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: pw.TextStyle(font: font),
          ),
        ],
      ),
    );

    return pdf;
  }

  // 🔹 PREVIEW (open print preview)
  static Future<void> generatePreview({
    required String firmName,
    required String buyerName,
    required String buyerCode,
    DateTime? fromDate,
    DateTime? toDate,
    required List<Map<String, dynamic>> ledger,
  }) async {
    final pdf = await _buildPdf(
      firmName: firmName,
      buyerName: buyerName,
      buyerCode: buyerCode,
      fromDate: fromDate,
      toDate: toDate,
      ledger: ledger,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // 🔹 FILE GENERATE (for WhatsApp share)
  static Future<File> generateFile({
    required String firmName,
    required String buyerName,
    required String buyerCode,
    DateTime? fromDate,
    DateTime? toDate,
    required List<Map<String, dynamic>> ledger,
  }) async {
    final pdf = await _buildPdf(
      firmName: firmName,
      buyerName: buyerName,
      buyerCode: buyerCode,
      fromDate: fromDate,
      toDate: toDate,
      ledger: ledger,
    );

    final dir = await getTemporaryDirectory();
    final file = File(
        "${dir.path}/buyer_ledger_${buyerCode}_${DateTime.now().millisecondsSinceEpoch}.pdf");

    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
