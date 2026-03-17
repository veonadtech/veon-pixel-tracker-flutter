import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'veon_pixel_tracker_flutter_platform_interface.dart';

/// An implementation of [VeonPixelTrackerFlutterPlatform] that uses method channels.
class MethodChannelVeonPixelTrackerFlutter extends VeonPixelTrackerFlutterPlatform {

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('veon_pixel_tracker_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

}
