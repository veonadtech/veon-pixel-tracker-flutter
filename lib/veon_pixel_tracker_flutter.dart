import 'package:flutter/services.dart';

class VeonPixelTracker {
  static const MethodChannel _initChannel =
  MethodChannel('com.veon.veon_pixel_tracker_flutter/android_init');

  static Future<void> initialize({
    required String baseUrl,
    bool debug = false,
  }) async {
    await _initChannel.invokeMethod('startPixelTracker', {
      "baseUrl": baseUrl,
      "debug": debug,
    });
  }

  static void listenInitialization(void Function(String status) onResult) {
    _initChannel.setMethodCallHandler((call) async {
      if (call.method == "pixelTrackerInitialized") {
        onResult("success");
      }

      if (call.method == "pixelTrackerInitializeFailed") {
        onResult("failed: ${call.arguments}");
      }
    });
  }
}