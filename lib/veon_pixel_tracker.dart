import 'dart:async';

import 'package:flutter/services.dart';
import 'package:veon_pixel_tracker_flutter/veon_pixel_tracker.dart';

export 'src/core/pixel_handle.dart';
export 'src/models/pixel_event.dart';
export 'src/models/pixel_stats.dart';
export 'src/widgets/pixel_tracker_view.dart';

class VeonPixelTracker {
  static const MethodChannel _methodChannel = MethodChannel(
    "veon_pixel_tracker/sdk",
  );

  static const EventChannel _eventChannel = EventChannel(
    "veon_pixel_tracker/events",
  );

  static Stream<Map<String, dynamic>>? _eventStream;

  /// Stream of SDK events (initialization, shutdown)
  static Stream<Map<String, dynamic>> get events {
    _eventStream ??= _eventChannel.receiveBroadcastStream().map(
      (event) => Map<String, dynamic>.from(event),
    );
    return _eventStream!;
  }

  /// Initialize the PixelTracker SDK
  static Future<void> initialize({
    required String baseUrl,
    bool debug = false,
  }) async {
    try {
      await _methodChannel.invokeMethod("initialize", {
        "baseUrl": baseUrl,
        "debug": debug,
      });
    } on PlatformException catch (e) {
      throw Exception("Failed to initialize PixelTracker: ${e.message}");
    }
  }

  /// Check if SDK is initialized
  static Future<bool> isInitialized() async {
    try {
      return await _methodChannel.invokeMethod("isInitialized");
    } on PlatformException catch (e) {
      throw Exception("Failed to check initialization: ${e.message}");
    }
  }

  /// Shutdown the SDK and clean up resources
  static Future<void> shutdown() async {
    try {
      await _methodChannel.invokeMethod("shutdown");
    } on PlatformException catch (e) {
      throw Exception("Failed to shutdown: ${e.message}");
    }
  }

  /// Create a new pixel
  static Future<PixelHandle> createPixel({
    required String pixelId,
    int refreshTimeSeconds = 0,
    int pixelSize = 1,
    int visibilityThreshold = 1,
    String? color,
  }) async {
    try {
      await _methodChannel.invokeMethod("createPixel", {
        "pixelId": pixelId,
        "refreshTimeSeconds": refreshTimeSeconds,
        "pixelSize": pixelSize,
        "visibilityThreshold": visibilityThreshold,
        "color": color,
      });
      return PixelHandle(pixelId);
    } on PlatformException catch (e) {
      throw Exception("Failed to create pixel: ${e.message}");
    }
  }

}
