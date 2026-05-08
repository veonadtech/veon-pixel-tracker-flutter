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

    test('start calls startPixel', () async {
      await controller.start();

      expect(calls, hasLength(1));

      expect(calls.single.method, 'startPixel');

      expect(
        calls.single.arguments,
        {
          'pixelId': testPixelId,
        },
      );
    });

    test('stop calls stopPixel', () async {
      await controller.stop();

      expect(calls, hasLength(1));

      expect(calls.single.method, 'stopPixel');

      expect(
        calls.single.arguments,
        {
          'pixelId': testPixelId,
        },
      );
    });

    test('destroy calls destroyPixel', () async {
      await controller.destroy();

      expect(calls, hasLength(1));

      expect(calls.single.method, 'destroyPixel');

      expect(
        calls.single.arguments,
        {
          'pixelId': testPixelId,
        },
      );
    });

    test('updateRefreshTime sends seconds', () async {
      await controller.updateRefreshTime(10);

      expect(calls, hasLength(1));

      expect(calls.single.method, 'updateRefreshTime');

      expect(
        calls.single.arguments,
        {
          'pixelId': testPixelId,
          'seconds': 10,
        },
      );
    });

    test('setVisibilityCheckInterval sends seconds', () async {
      await controller.setVisibilityCheckInterval(5);

      expect(calls, hasLength(1));

      expect(calls.single.method, 'setVisibilityCheckInterval');

      expect(
        calls.single.arguments,
        {
          'pixelId': testPixelId,
          'seconds': 5,
        },
      );
    });

    test('getStats returns parsed PixelStats', () async {
      final stats = await controller.getStats();

      expect(stats, isA<PixelStats>());

      expect(stats.totalAppearances, 3);
      expect(stats.isCurrentlyVisible, isTrue);
      expect(stats.refreshEnabled, isTrue);
      expect(stats.nextRefreshInMs, 4000);
    });

    test('getStats throws when native result null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => null);

      expect(
            () => controller.getStats(),
        throwsException,
      );
    });

    test('multiple controllers use correct pixel ids', () async {
      final controllerA = PixelController('pixel_a');
      final controllerB = PixelController('pixel_b');

      await controllerA.start();
      await controllerB.stop();

      expect(calls, hasLength(2));

      expect(
        calls[0].arguments,
        {
          'pixelId': 'pixel_a',
        },
      );

      expect(
        calls[1].arguments,
        {
          'pixelId': 'pixel_b',
        },
      );
    });
  });
}