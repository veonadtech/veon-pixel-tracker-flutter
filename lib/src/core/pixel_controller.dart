import 'package:flutter/services.dart';
import 'package:veon_pixel_tracker_flutter/src/models/pixel_stats.dart';

class PixelController {
  final String pixelId;

  static const MethodChannel _methodChannel = MethodChannel(
    "veon_pixel_tracker/sdk",
  );

  PixelController(this.pixelId);

  Future<void> start() async {
    await _methodChannel.invokeMethod("startPixel", {"pixelId": pixelId});
  }

  Future<void> stop() async {
    await _methodChannel.invokeMethod("stopPixel", {"pixelId": pixelId});
  }

  Future<void> destroy() async {
    await _methodChannel.invokeMethod("destroyPixel", {"pixelId": pixelId});
  }

  Future<void> updateRefreshTime(int seconds) async {
    await _methodChannel.invokeMethod("updateRefreshTime", {
      "pixelId": pixelId,
      "seconds": seconds,
    });
  }

  Future<void> setVisibilityCheckInterval(int seconds) async {
    await _methodChannel.invokeMethod("setVisibilityCheckInterval", {
      "pixelId": pixelId,
      "seconds": seconds,
    });
  }

  Future<PixelStats> getStats() async {
    final result = await _methodChannel.invokeMethod<Map>("getPixelStats", {
      "pixelId": pixelId,
    });

    if (result == null) {
      throw Exception("Stats is null");
    }

    return PixelStats.fromMap(Map<String, dynamic>.from(result));
  }
}
