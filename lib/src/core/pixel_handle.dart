import 'package:flutter/services.dart';
import 'package:veon_pixel_tracker_flutter/src/models/pixel_stats.dart';

/// Represents a pixel instance
class PixelHandle {
  final String _pixelId;
  static const String _channelName = "veon_pixel_tracker/sdk";
  static const MethodChannel _methodChannel = MethodChannel(_channelName);

  PixelHandle(this._pixelId);

  /// Start tracking this pixel
  Future<void> start() async {
    try {
      await _methodChannel.invokeMethod("startPixel", {"pixelId": _pixelId});
    } on PlatformException catch (e) {
      throw Exception("Failed to start pixel: ${e.message}");
    }
  }

  /// Stop tracking this pixel
  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod("stopPixel", {"pixelId": _pixelId});
    } on PlatformException catch (e) {
      throw Exception("Failed to stop pixel: ${e.message}");
    }
  }

  /// Destroy this pixel and clean up resources
  Future<void> destroy() async {
    try {
      await _methodChannel.invokeMethod("destroyPixel", {"pixelId": _pixelId});
    } on PlatformException catch (e) {
      throw Exception("Failed to destroy pixel: ${e.message}");
    }
  }

  /// Update refresh time interval
  Future<void> updateRefreshTime(int seconds) async {
    try {
      await _methodChannel.invokeMethod("updateRefreshTime", {
        "pixelId": _pixelId,
        "seconds": seconds,
      });
    } on PlatformException catch (e) {
      throw Exception("Failed to update refresh time: ${e.message}");
    }
  }

  /// Set visibility check interval
  Future<void> setVisibilityCheckInterval(int seconds) async {
    try {
      await _methodChannel.invokeMethod("setVisibilityCheckInterval", {
        "pixelId": _pixelId,
        "seconds": seconds,
      });
    } on PlatformException catch (e) {
      throw Exception("Failed to set visibility check interval: ${e.message}");
    }
  }

  /// Get current pixel statistics
  Future<PixelStats> getStats() async {
    try {
      final Map<dynamic, dynamic> result = await _methodChannel.invokeMethod(
        "getPixelStats",
        {"pixelId": _pixelId},
      );
      return PixelStats.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw Exception("Failed to get stats: ${e.message}");
    }
  }

}
