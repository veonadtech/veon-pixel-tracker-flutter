import 'dart:async';
import 'package:flutter/services.dart';

export 'src/core/pixel_controller.dart';
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

  static Stream<Map<String, dynamic>> get events {
    final existing = _eventStream;
    if (existing != null) return existing;

    final stream = _eventChannel.receiveBroadcastStream().map(
      (event) => Map<String, dynamic>.from(event as Map),
    );

    _eventStream = stream;
    return stream;
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
}
