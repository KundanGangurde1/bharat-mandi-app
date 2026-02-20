import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'payment_model.dart';

class PaymentPdfGenerator {
  /// Generate PDF for payment receipt
  static Future<File?> generatePaymentPDF(Payment payment) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'जमा पावती',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Payment Details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('खरीददार: ${payment.buyer_name}'),
                        pw.Text('कोड: ${payment.buyer_code}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('तारीख: ${payment.getFormattedDate()}'),
                        pw.Text('समय: ${payment.getFormattedDateTime()}'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Amount Details
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('राशि:'),
                          pw.Text(payment.getFormattedAmount()),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('भुगतान विधि:'),
                          pw.Text(payment.getPaymentModeDisplay()),
                        ],
                      ),
                      if (payment.reference_no != null &&
                          payment.reference_no!.isNotEmpty)
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('संदर्भ संख्या:'),
                            pw.Text(payment.reference_no!),
                          ],
                        ),
                      if (payment.notes != null && payment.notes!.isNotEmpty)
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('टिप्पणी:'),
                            pw.Text(payment.notes!),
                          ],
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Footer
                pw.Center(
                  child: pw.Text(
                    'धन्यवाद!',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF
      final output = await getApplicationDocumentsDirectory();
      final file = File(
        '${output.path}/payment_${payment.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      return file;
    } catch (e) {
      print('❌ Error generating PDF: $e');
      return null;
    }
  }
}
