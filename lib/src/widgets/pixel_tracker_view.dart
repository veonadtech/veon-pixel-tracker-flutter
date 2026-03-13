import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veon_pixel_tracker_flutter/src/models/pixel_event.dart';

class PixelTrackerView extends StatefulWidget {
  final String pixelId;
  final int refreshTimeSeconds;
  final int pixelSize;
  final int visibilityThreshold;
  final String? color;
  final Function(PixelEvent)? onEvent;

  const PixelTrackerView({
    Key? key,
    required this.pixelId,
    this.refreshTimeSeconds = 0,
    this.pixelSize = 1,
    this.visibilityThreshold = 1,
    this.color,
    this.onEvent,
  }) : super(key: key);

  @override
  State<PixelTrackerView> createState() => _PixelTrackerViewState();
}

class _PixelTrackerViewState extends State<PixelTrackerView> {
  final _eventChannels = <int, EventChannel>{};
  StreamSubscription? _eventSubscription;

  void _onPlatformViewCreated(int viewId) {
    final eventChannel = EventChannel('veon_pixel_tracker/view_events_$viewId');
    _eventChannels[viewId] = eventChannel;

    _eventSubscription = eventChannel.receiveBroadcastStream().listen((event) {
      final eventMap = Map<String, dynamic>.from(event);
      final type = eventMap['type'] as String;
      final timestamp = eventMap['timestamp'] as String;
      final error = eventMap['error'] as String?;

      widget.onEvent?.call(PixelEvent(type, timestamp, error));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: 'veon_pixel_tracker_view_default',
      onPlatformViewCreated: _onPlatformViewCreated,
      creationParams: {
        'pixelId': widget.pixelId,
        'refreshTimeSeconds': widget.refreshTimeSeconds,
        'pixelSize': widget.pixelSize,
        'visibilityThreshold': widget.visibilityThreshold,
        'color': widget.color,
      },
      creationParamsCodec: const StandardMessageCodec(),
    );
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _eventChannels.clear();
    super.dispose();
  }
}

/// Pixel event class (если еще не определен)
class PixelEvent {
  final String type;
  final String timestamp;
  final String? error;

  PixelEvent(this.type, this.timestamp, this.error);

  bool get isAppearance => type == 'appearance';
  bool get isDisappearance => type == 'disappearance';
  bool get isRefresh => type == 'refresh';
  bool get isError => type == 'error';
}