import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'veon_pixel_tracker_flutter_method_channel.dart';

abstract class VeonPixelTrackerFlutterPlatform extends PlatformInterface {
  /// Constructs a VeonPixelTrackerFlutterPlatform.
  VeonPixelTrackerFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static VeonPixelTrackerFlutterPlatform _instance =
      MethodChannelVeonPixelTrackerFlutter();

  /// The default instance of [VeonPixelTrackerFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelVeonPixelTrackerFlutter].
  static VeonPixelTrackerFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VeonPixelTrackerFlutterPlatform] when
  /// they register themselves.
  static set instance(VeonPixelTrackerFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

}
