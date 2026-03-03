import 'package:flutter_test/flutter_test.dart';
import 'package:veon_pixel_tracker_flutter/veon_pixel_tracker_flutter.dart';
import 'package:veon_pixel_tracker_flutter/veon_pixel_tracker_flutter_platform_interface.dart';
import 'package:veon_pixel_tracker_flutter/veon_pixel_tracker_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockVeonPixelTrackerFlutterPlatform
    with MockPlatformInterfaceMixin
    implements VeonPixelTrackerFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final VeonPixelTrackerFlutterPlatform initialPlatform = VeonPixelTrackerFlutterPlatform.instance;

  test('$MethodChannelVeonPixelTrackerFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVeonPixelTrackerFlutter>());
  });

  test('getPlatformVersion', () async {
    VeonPixelTrackerFlutter veonPixelTrackerFlutterPlugin = VeonPixelTrackerFlutter();
    MockVeonPixelTrackerFlutterPlatform fakePlatform = MockVeonPixelTrackerFlutterPlatform();
    VeonPixelTrackerFlutterPlatform.instance = fakePlatform;

    expect(await veonPixelTrackerFlutterPlugin.getPlatformVersion(), '42');
  });
}
