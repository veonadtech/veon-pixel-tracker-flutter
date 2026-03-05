import 'dart:async';
import 'package:flutter/services.dart';

class VeonPixelTracker {

  static const MethodChannel _methodChannel =
  MethodChannel("veon_pixel_tracker/sdk");

  static const EventChannel _eventChannel =
  EventChannel("veon_pixel_tracker/events");

  static Stream<Map>? _eventStream;

  static Stream<Map> get events {
    _eventStream ??=
        _eventChannel.receiveBroadcastStream().cast<Map>();
    return _eventStream!;
  }

  static Future<void> initialize({
    required String baseUrl,
    bool debug = false,
  }) async {

    await _methodChannel.invokeMethod(
      "initialize",
      {
        "baseUrl": baseUrl,
        "debug": debug,
      },
    );
  }

}