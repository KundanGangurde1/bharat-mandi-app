import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BuyerLedgerPdf {
  static Future<void> generate({
    required String firmName,
    required String buyerName,
    required String buyerCode,
    DateTime? fromDate,
    DateTime? toDate,
    required List<Map<String, dynamic>> ledger,
  }) async {
    final pdf = pw.Document();

    // 🔤 LOAD MARATHI (UNICODE) FONTS
    final marathiFont = pw.Font.ttf(
      await rootBundle.load(
        'assets/fonts/NotoSansDevanagari-Regular.ttf',
      ),
    );

    final marathiBoldFont = pw.Font.ttf(
      await rootBundle.load(
        'assets/fonts/NotoSansDevanagari-Bold.ttf',
      ),
    );

    // 🔢 TOTALS
    double totalDebit = 0.0;
    double totalCredit = 0.0;

    for (final row in ledger) {
      totalDebit += (row['debit'] as double? ?? 0.0);
      totalCredit += (row['credit'] as double? ?? 0.0);
    }

    // 📊 TABLE HEADERS
    final headers = [
      'दिनांक',
      'तपशील',
      'Ref',
      'डेबिट',
      'क्रेडिट',
      'शिल्लक',
    ];

    // 📊 TABLE DATA
    final data = ledger.map((row) {
      return [
        row['date'] == null
            ? '-'
            : DateFormat('dd/MM/yyyy').format(DateTime.parse(row['date'])),
        row['type'] ?? '',
        row['ref']?.toString() ?? '',
        (row['debit'] ?? 0) > 0
            ? '₹${(row['debit'] as double).toStringAsFixed(2)}'
            : '',
        (row['credit'] ?? 0) > 0
            ? '₹${(row['credit'] as double).toStringAsFixed(2)}'
            : '',
        '₹${(row['balance'] as double).toStringAsFixed(2)}',
      ];
    }).toList();

    // 📄 PDF PAGE
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),

        // 🔻 FOOTER
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'एकूण डेबिट: ₹${totalDebit.toStringAsFixed(2)}   |   '
              'एकूण क्रेडिट: ₹${totalCredit.toStringAsFixed(2)}',
              style: pw.TextStyle(
                font: marathiFont,
                fontSize: 10,
              ),
            ),
            pw.Text(
              'Page ${context.pageNumber}',
              style: pw.TextStyle(
                font: marathiFont,
                fontSize: 10,
              ),
            ),
          ],
        ),

        build: (context) => [
          // 🔝 HEADER
          pw.Text(
            firmName,
            style: pw.TextStyle(
              font: marathiBoldFont,
              fontSize: 18,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'खरेदीदार: $buyerName ($buyerCode)',
            style: pw.TextStyle(font: marathiFont),
          ),
          if (fromDate != null || toDate != null)
            pw.Text(
              'कालावधी: '
              '${fromDate != null ? DateFormat('dd/MM/yyyy').format(fromDate) : '-'}'
              ' ते '
              '${toDate != null ? DateFormat('dd/MM/yyyy').format(toDate) : '-'}',
              style: pw.TextStyle(font: marathiFont, fontSize: 11),
            ),
          pw.Divider(),
          pw.SizedBox(height: 10),

          // 📄 LEDGER TABLE
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            border: pw.TableBorder.all(),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(
              font: marathiBoldFont,
              fontSize: 10,
            ),
            cellStyle: pw.TextStyle(
              font: marathiFont,
              fontSize: 9,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(1.6),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1.3),
            },
          ),
        ],
      ),
    );

    // 🖨️ PRINT / SHARE
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}
