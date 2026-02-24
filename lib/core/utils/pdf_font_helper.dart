import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfFontHelper {
  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<pw.Font> regular() async {
    if (_regular != null) return _regular!;
    final regularData =
        await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
    _regular = pw.Font.ttf(regularData);
    return _regular!;
  }

  static Future<pw.Font> bold() async {
    if (_bold != null) return _bold!;
    try {
      final boldData =
          await rootBundle.load('assets/fonts/NotoSansDevanagari-Bold.ttf');
      _bold = pw.Font.ttf(boldData);
    } catch (_) {
      _bold = await regular();
    }
    return _bold!;
  }
}
