import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Payment Ledger PDF Generator
/// Generates professional PDF for payment entries with Marathi support
class PaymentLedgerPdf {
  /// Build PDF document for payment
  static Future<pw.Document> _buildPdf({
    required String firmName,
    required String buyerName,
    required String buyerCode,
    required String paymentId,
    required double amount,
    required String paymentMode,
    required String reference,
    required DateTime paymentDate,
    required double openingBalance,
    required double remainingBalance,
    required List<Map<String, dynamic>> ledger,
  }) async {
    final pdf = pw.Document();

    // Load Marathi font
    final fontData =
        await rootBundle.load("assets/fonts/NotoSansDevanagari-Regular.ttf");
    final font = pw.Font.ttf(fontData);

    // Payment mode in Marathi
    final paymentModeMarathi = _getPaymentModeMarathi(paymentMode);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // Header
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
            'वसूली पावती (Payment Receipt)',
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),

          // Payment Details Header
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              color: PdfColors.grey300,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'पावती क्र.: $paymentId',
                          style: pw.TextStyle(font: font, fontSize: 11),
                        ),
                        pw.Text(
                          'दिनांक: ${DateFormat('dd/MM/yyyy').format(paymentDate)}',
                          style: pw.TextStyle(font: font, fontSize: 11),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'खरेदीदार: $buyerName',
                          style: pw.TextStyle(font: font, fontSize: 11),
                        ),
                        pw.Text(
                          'कोड: $buyerCode',
                          style: pw.TextStyle(font: font, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Payment Summary Box (Simple format)
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 2),
              color: PdfColors.blue50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Opening Balance
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'उघडलेली रक्कम:',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '₹ ${openingBalance.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Payment Amount (Green)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'जमा रक्कम:',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                    pw.Text(
                      '₹ ${amount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.SizedBox(height: 8),

                // Remaining Balance
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'शिल्लक:',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '₹ ${remainingBalance.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Payment Mode & Reference
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'वसूली पद्धति: $paymentModeMarathi',
                  style: pw.TextStyle(font: font, fontSize: 11),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'संदर्भ: $reference',
                  style: pw.TextStyle(font: font, fontSize: 11),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Ledger Table (if available)
          if (ledger.isNotEmpty) ...[
            pw.Text(
              'लेखा विवरण (Transaction History)',
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'दिनांक',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'तपशील',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'उघडलेली',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'जमा',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'शिल्लक',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                // Data rows
                ...ledger.map((row) {
                  final date = row['date'] != null
                      ? DateFormat('dd/MM/yyyy')
                          .format(DateTime.parse(row['date'].toString()))
                      : '-';
                  final type = row['type']?.toString() ?? '-';
                  final udhari = (row['udhari'] as num? ?? 0).toDouble();
                  final jama = (row['jama'] as num? ?? 0).toDouble();
                  final balance = (row['balance'] as num? ?? 0).toDouble();

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          date,
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          type,
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          udhari > 0 ? udhari.toStringAsFixed(2) : '',
                          style: pw.TextStyle(font: font, fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          jama > 0 ? jama.toStringAsFixed(2) : '',
                          style: pw.TextStyle(font: font, fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          balance.toStringAsFixed(2),
                          style: pw.TextStyle(font: font, fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],

          pw.SizedBox(height: 20),
          pw.Text(
            'यह पावती डिजिटली तयार केली गेली आहे.',
            style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey),
          ),
        ],
      ),
    );

    return pdf;
  }

  /// Generate PDF preview (print preview)
  static Future<void> generatePreview({
    required String firmName,
    required String buyerName,
    required String buyerCode,
    required String paymentId,
    required double amount,
    required String paymentMode,
    required String reference,
    required DateTime paymentDate,
    required double openingBalance,
    required double remainingBalance,
    required List<Map<String, dynamic>> ledger,
  }) async {
    final pdf = await _buildPdf(
      firmName: firmName,
      buyerName: buyerName,
      buyerCode: buyerCode,
      paymentId: paymentId,
      amount: amount,
      paymentMode: paymentMode,
      reference: reference,
      paymentDate: paymentDate,
      openingBalance: openingBalance,
      remainingBalance: remainingBalance,
      ledger: ledger,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  /// Generate PDF file (for sharing)
  static Future<File> generateFile({
    required String firmName,
    required String buyerName,
    required String buyerCode,
    required String paymentId,
    required double amount,
    required String paymentMode,
    required String reference,
    required DateTime paymentDate,
    required double openingBalance,
    required double remainingBalance,
    required List<Map<String, dynamic>> ledger,
  }) async {
    final pdf = await _buildPdf(
      firmName: firmName,
      buyerName: buyerName,
      buyerCode: buyerCode,
      paymentId: paymentId,
      amount: amount,
      paymentMode: paymentMode,
      reference: reference,
      paymentDate: paymentDate,
      openingBalance: openingBalance,
      remainingBalance: remainingBalance,
      ledger: ledger,
    );

    final dir = await getTemporaryDirectory();
    final file = File(
        "${dir.path}/payment_${buyerCode}_${paymentId}_${DateTime.now().millisecondsSinceEpoch}.pdf");

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Get payment mode in Marathi
  static String _getPaymentModeMarathi(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash':
        return 'रोख';
      case 'bank':
        return 'बँक';
      case 'upi':
        return 'यूपीआई';
      case 'cheque':
        return 'चेक';
      default:
        return mode;
    }
  }
}
