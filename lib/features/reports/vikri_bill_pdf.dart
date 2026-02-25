import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../core/utils/pdf_font_helper.dart';

class VikriBillPdf {
  /// Generate Buyer Invoice (विक्री बिल) PDF
  static Future<pw.Document> generateBuyerBill({
    required String firmName,
    required String mobileNumber,
    required String buyerName,
    required String buyerCode,
    required DateTime billDate,
    required List<Map<String, dynamic>>
        transactions, // All transactions for this buyer on this date
    required List<Map<String, dynamic>>
        expenses, // All expenses for this buyer on this date
    required double openingBalance,
    required double totalPayments,
  }) async {
    final doc = pw.Document();
    final regularFont = await PdfFontHelper.regular();
    final boldFont = await PdfFontHelper.bold();

    // Calculate totals
    double totalGross = 0;
    double totalExpenseAmount = 0;

    for (final txn in transactions) {
      totalGross += (txn['gross'] as num?)?.toDouble() ?? 0.0;
    }

    for (final exp in expenses) {
      totalExpenseAmount += (exp['amount'] as num?)?.toDouble() ?? 0.0;
    }

    final netAmount = totalGross - totalExpenseAmount;
    final finalBalance =
        openingBalance + totalGross - totalExpenseAmount - totalPayments;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '|| श्री ||',
                    style: pw.TextStyle(font: boldFont, fontSize: 16),
                  ),
                  pw.Text(
                    'मो. $mobileNumber',
                    style: pw.TextStyle(font: regularFont, fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                firmName,
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

              // Bill Title and Date
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'नाव बिल',
                    style: pw.TextStyle(font: boldFont, fontSize: 14),
                  ),
                  pw.Text(
                    'तारीख: ${DateFormat('dd/MM/yyyy').format(billDate)}',
                    style: pw.TextStyle(font: regularFont, fontSize: 11),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // Buyer Info
              pw.Text(
                'खरीददार: $buyerName ($buyerCode)',
                style: pw.TextStyle(font: regularFont, fontSize: 11),
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

              // Items Table Header
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3), // माल का नाव
                  1: const pw.FlexColumnWidth(1.5), // डाग
                  2: const pw.FlexColumnWidth(1.5), // वजन
                  3: const pw.FlexColumnWidth(1.5), // भाव रु.
                  4: const pw.FlexColumnWidth(2), // एकुण रक्कम
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFE8E8E8),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'माल का नाव',
                          style: pw.TextStyle(font: boldFont, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'डाग',
                          style: pw.TextStyle(font: boldFont, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'वजन',
                          style: pw.TextStyle(font: boldFont, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'भाव रु.',
                          style: pw.TextStyle(font: boldFont, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'एकुण रक्कम',
                          style: pw.TextStyle(font: boldFont, fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  // Data Rows
                  ...transactions.map((txn) {
                    final produceName = txn['produce_name']?.toString() ?? '-';
                    final quantity =
                        (txn['quantity'] as num?)?.toDouble() ?? 0.0;
                    final rate = (txn['rate'] as num?)?.toDouble() ?? 0.0;
                    final gross = (txn['gross'] as num?)?.toDouble() ?? 0.0;

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            produceName,
                            style: pw.TextStyle(font: regularFont, fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            quantity.toStringAsFixed(2),
                            style: pw.TextStyle(font: regularFont, fontSize: 9),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            rate.toStringAsFixed(2),
                            style: pw.TextStyle(font: regularFont, fontSize: 9),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            rate.toStringAsFixed(2),
                            style: pw.TextStyle(font: regularFont, fontSize: 9),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            gross.toStringAsFixed(2),
                            style: pw.TextStyle(font: regularFont, fontSize: 9),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 8),

              // Summary Section - Left side (Expenses) and Right side (Totals)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left Column - Expenses
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'खर्च विवरण:',
                          style: pw.TextStyle(font: boldFont, fontSize: 10),
                        ),
                        pw.SizedBox(height: 4),
                        ...expenses.map((exp) {
                          final expenseName =
                              exp['expense_name']?.toString() ?? 'खर्च';
                          final amount =
                              (exp['amount'] as num?)?.toDouble() ?? 0.0;
                          return pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 2),
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  expenseName,
                                  style: pw.TextStyle(
                                      font: regularFont, fontSize: 9),
                                ),
                                pw.Text(
                                  amount.toStringAsFixed(2),
                                  style: pw.TextStyle(
                                      font: regularFont, fontSize: 9),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Right Column - Totals
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'एकुण रक्कम:',
                              style:
                                  pw.TextStyle(font: regularFont, fontSize: 10),
                            ),
                            pw.Text(
                              totalGross.toStringAsFixed(2),
                              style:
                                  pw.TextStyle(font: regularFont, fontSize: 10),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'एकुण खर्च:',
                              style:
                                  pw.TextStyle(font: regularFont, fontSize: 10),
                            ),
                            pw.Text(
                              totalExpenseAmount.toStringAsFixed(2),
                              style:
                                  pw.TextStyle(font: regularFont, fontSize: 10),
                            ),
                          ],
                        ),
                        pw.Divider(thickness: 1),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'नेट रक्कम:',
                              style: pw.TextStyle(font: boldFont, fontSize: 10),
                            ),
                            pw.Text(
                              netAmount.toStringAsFixed(2),
                              style: pw.TextStyle(font: boldFont, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

              // Balance Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'मांगील बाकी:',
                        style: pw.TextStyle(font: regularFont, fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        openingBalance.toStringAsFixed(2),
                        style: pw.TextStyle(font: regularFont, fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'एकुण बाकी:',
                        style: pw.TextStyle(font: boldFont, fontSize: 11),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        finalBalance.toStringAsFixed(2),
                        style: pw.TextStyle(font: boldFont, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Footer Note
              pw.Text(
                'चुकभूल देनेघेने',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 9,
                  color: PdfColor.fromInt(0xFF808080),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc;
  }
}
