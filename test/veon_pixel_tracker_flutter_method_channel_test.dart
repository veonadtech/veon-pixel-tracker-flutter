import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veon_pixel_tracker_flutter/veon_pixel_tracker_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelVeonPixelTrackerFlutter platform = MethodChannelVeonPixelTrackerFlutter();
  const MethodChannel channel = MethodChannel('veon_pixel_tracker_flutter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
