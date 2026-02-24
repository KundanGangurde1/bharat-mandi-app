import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/pdf_font_helper.dart';

class PavtiPdfService {
  static Future<pw.Document> buildPavtiPdf({
    required String parchiId,
    required String farmerName,
    required String farmerCode,
    required String formattedDate,
    required List<Map<String, dynamic>> entries,
    required double totalExpense,
    required double net,
  }) async {
    final gross = entries.fold<double>(
      0,
      (sum, e) => sum + ((e['gross'] as num?)?.toDouble() ?? 0.0),
    );

    final regularFont = await PdfFontHelper.regular();
    final boldFont = await PdfFontHelper.bold();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'पावती तपशील',
            style: pw.TextStyle(font: boldFont, fontSize: 18),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'पावती नं: $parchiId',
            style: pw.TextStyle(font: regularFont),
          ),
          pw.Text(
            'शेतकरी: $farmerName ($farmerCode)',
            style: pw.TextStyle(font: regularFont),
          ),
          pw.Text(
            'तारीख: $formattedDate',
            style: pw.TextStyle(font: regularFont),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(font: boldFont),
            cellStyle: pw.TextStyle(font: regularFont),
            headers: const ['व्यापारी', 'माल', 'प्रमाण', 'दर', 'रक्कम'],
            data: entries.map((e) {
              return [
                (e['buyer_name'] ?? '').toString(),
                (e['produce_name'] ?? '').toString(),
                ((e['quantity'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
                ((e['rate'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
                ((e['gross'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'एकूण रक्कम: ₹${gross.toStringAsFixed(2)}',
            style: pw.TextStyle(font: regularFont),
          ),
          pw.Text(
            'एकूण खर्च: ₹${totalExpense.toStringAsFixed(2)}',
            style: pw.TextStyle(font: regularFont),
          ),
          pw.Text(
            'शुद्ध रक्कम: ₹${net.toStringAsFixed(2)}',
            style: pw.TextStyle(font: boldFont),
          ),
        ],
      ),
    );

    return doc;
  }

  static Future<void> previewPdf(BuildContext context, pw.Document doc) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('पावती PDF प्रीव्ह्यू'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          body: PdfPreview(
            build: (format) async => doc.save(),
            canChangePageFormat: false,
            canChangeOrientation: false,
          ),
        ),
      ),
    );
  }

  static Future<void> printPdf(pw.Document doc) async {
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  static Future<void> sharePdf(pw.Document doc, String parchiId) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pavti_$parchiId.pdf');
    await file.writeAsBytes(await doc.save());
    await Share.shareXFiles([XFile(file.path)], text: 'पावती नं: $parchiId');
  }
}
