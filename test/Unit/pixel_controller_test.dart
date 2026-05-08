import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veon_pixel_tracker_flutter/src/core/pixel_controller.dart';
import 'package:veon_pixel_tracker_flutter/src/models/pixel_stats.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('veon_pixel_tracker/sdk');
  const testPixelId = 'test_pixel_1';

  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call);
      switch (call.method) {
        case 'getPixelStats':
          return {
            'totalAppearances': 3,
            'isCurrentlyVisible': true,
            'refreshEnabled': true,
            'nextRefreshInMs': 4000,
          };
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('PixelController', () {
    late PixelController controller;

    setUp(() {
      controller = PixelController(testPixelId);
    });

    test('start() calls startPixel with correct pixelId', () async {
      await controller.start();

      expect(calls.length, 1);
      expect(calls.last.method, 'startPixel');
      expect(calls.last.arguments['pixelId'], testPixelId);
    });

    test('stop() calls stopPixel with correct pixelId', () async {
      await controller.stop();

      expect(calls.length, 1);
      expect(calls.last.method, 'stopPixel');
      expect(calls.last.arguments['pixelId'], testPixelId);
    });

    test('destroy() calls destroyPixel with correct pixelId', () async {
      await controller.destroy();

      expect(calls.length, 1);
      expect(calls.last.method, 'destroyPixel');
      expect(calls.last.arguments['pixelId'], testPixelId);
    });

    test('updateRefreshTime() sends correct seconds', () async {
      await controller.updateRefreshTime(10);

      expect(calls.last.method, 'updateRefreshTime');
      expect(calls.last.arguments['pixelId'], testPixelId);
      expect(calls.last.arguments['seconds'], 10);
    });

    test('setVisibilityCheckInterval() sends correct seconds', () async {
      await controller.setVisibilityCheckInterval(5);

      expect(calls.last.method, 'setVisibilityCheckInterval');
      expect(calls.last.arguments['pixelId'], testPixelId);
      expect(calls.last.arguments['seconds'], 5);
    });

    test('getStats() returns parsed PixelStats', () async {
      final stats = await controller.getStats();

      expect(stats, isA<PixelStats>());
      expect(stats.totalAppearances, 3);
      expect(stats.isCurrentlyVisible, isTrue);
      expect(stats.refreshEnabled, isTrue);
      expect(stats.nextRefreshInMs, 4000);
    });

    test('getStats() throws when result is null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);

      expect(() => controller.getStats(), throwsException);
    });

    test('each method targets the correct pixelId', () async {
      final c1 = PixelController('pixel_a');
      final c2 = PixelController('pixel_b');

      await c1.start();
      await c2.stop();

      expect(calls[0].arguments['pixelId'], 'pixel_a');
      expect(calls[1].arguments['pixelId'], 'pixel_b');
    });
  });
}
