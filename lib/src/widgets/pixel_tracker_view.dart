import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veon_pixel_tracker_flutter/src/models/pixel_event.dart';
import 'package:veon_pixel_tracker_flutter/src/core/pixel_controller.dart';

class PixelTrackerView extends StatefulWidget {
  final String pixelId;
  final int refreshTimeSeconds;
  final int pixelSize;
  final int visibilityThreshold;
  final String? color;
  final Function(PixelEvent)? onEvent;
  final Function(PixelController)? onPixelCreated;

  const PixelTrackerView({
    super.key,
    required this.pixelId,
    this.refreshTimeSeconds = 0,
    this.pixelSize = 1,
    this.visibilityThreshold = 1,
    this.color,
    this.onEvent,
    this.onPixelCreated,
  });

  @override
  State<PixelTrackerView> createState() => _PixelTrackerViewState();
}

class _PixelTrackerViewState extends State<PixelTrackerView> {
  StreamSubscription? _eventSubscription;
  bool _isCreated = false;
  PixelController? _controller;

  void _onPlatformViewCreated(int viewId) {
    if (_isCreated) return;
    _isCreated = true;

    final controller = PixelController(widget.pixelId);
    _controller = controller;
    widget.onPixelCreated?.call(controller);

    final eventChannel = EventChannel('veon_pixel_tracker/view_events_$viewId');
    _eventSubscription = eventChannel.receiveBroadcastStream().listen((event) {
      final map = Map<String, dynamic>.from(event as Map);
      widget.onEvent?.call(PixelEvent.fromMap(map));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.pixelSize.toDouble(),
      height: widget.pixelSize.toDouble(),
      child: AndroidView(
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
      ),
    );
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}
