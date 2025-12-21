import 'package:flutter/services.dart';

class OcrService {
  const OcrService();

  static const MethodChannel _channel = MethodChannel('paddle_ocr');
  static const MethodChannel _floatingChannel = MethodChannel('floating_ocr');
  static const EventChannel _floatingEvents = EventChannel('floating_ocr_events');

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

  /// 启动悬浮截屏服务，要求已授予悬浮窗和录屏权限。
  Future<void> startFloatingOcr() async {
    await _floatingChannel.invokeMethod<void>('startFloatingOcr');
  }

  /// 停止悬浮截屏服务。
  Future<void> stopFloatingOcr() async {
    await _floatingChannel.invokeMethod<void>('stopFloatingOcr');
  }

  /// 监听悬浮截屏状态与结果：status = ready|capturing|success|error。
  Stream<Map<String, dynamic>> floatingEvents() {
    return _floatingEvents
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map));
  }
}
