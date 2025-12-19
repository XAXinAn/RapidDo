import 'package:flutter/services.dart';

class OcrService {
  const OcrService();

  static const MethodChannel _channel = MethodChannel('paddle_ocr');

  Future<String> recognize(String imagePath) async {
    try {
      final String? text = await _channel.invokeMethod<String>(
        'recognize',
        {'imagePath': imagePath},
      );
      return text ?? '';
    } on PlatformException catch (e) {
      // Surface a concise message to the caller; caller can decide how to show it.
      throw Exception('OCR unavailable: ${e.code}: ${e.message ?? 'no details'}');
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
  }
}
