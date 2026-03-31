import 'package:flutter/services.dart';
import 'package:veon_pixel_tracker_flutter/src/models/pixel_stats.dart';

class PixelController {
  final String pixelId;

  static const MethodChannel _methodChannel = MethodChannel("veon_pixel_tracker/sdk");

  bool _isDestroyed = false;

  PixelController(this.pixelId);

  void _ensureNotDestroyed() {
    if (_isDestroyed) {
      throw Exception("PixelController already destroyed");
    }
  }

  Future<void> start() async {
    _ensureNotDestroyed();
    await _methodChannel.invokeMethod("startPixel", {"pixelId": pixelId});
  }

  Future<void> stop() async {
    _ensureNotDestroyed();
    await _methodChannel.invokeMethod("stopPixel", {"pixelId": pixelId});
  }

  Future<void> destroy() async {
    if (_isDestroyed) return;
    _isDestroyed = true;
    try {
      await _methodChannel.invokeMethod("destroyPixel", {"pixelId": pixelId});
    } on PlatformException catch (e) {
      if (e.code != 'PIXEL_NOT_FOUND') {
        throw Exception("Failed to destroy pixel: ${e.message}");
      }
    }
  }

  Future<void> updateRefreshTime(int seconds) async {
    _ensureNotDestroyed();
    await _methodChannel.invokeMethod("updateRefreshTime", {
      "pixelId": pixelId,
      "seconds": seconds,
    });
  }

  Future<void> setVisibilityCheckInterval(int seconds) async {
    _ensureNotDestroyed();
    await _methodChannel.invokeMethod("setVisibilityCheckInterval", {
      "pixelId": pixelId,
      "seconds": seconds,
    });
  }

  Future<PixelStats> getStats() async {
    _ensureNotDestroyed();
    final result = await _methodChannel.invokeMethod<Map>("getPixelStats", {
      "pixelId": pixelId,
    });
    if (result == null) {
      throw Exception("Failed to get stats: result is null");
    }
    return PixelStats.fromMap(Map<String, dynamic>.from(result));
  }
}