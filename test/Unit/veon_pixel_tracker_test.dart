import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veon_pixel_tracker_flutter/veon_pixel_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('veon_pixel_tracker/sdk');

  late List<MethodCall> calls;

  setUp(() {
    calls = [];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call);

      switch (call.method) {
        case 'initialize':
          return null;

        case 'isInitialized':
          return true;

        case 'shutdown':
          return null;

        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('VeonPixelTracker', () {
    test('initialize sends baseUrl and debug false by default', () async {
      await VeonPixelTracker.initialize(
        baseUrl: 'https://example.com/pixel',
      );

      expect(calls, hasLength(1));

      expect(calls.single.method, 'initialize');

      expect(
        calls.single.arguments,
        {
          'baseUrl': 'https://example.com/pixel',
          'debug': false,
        },
      );
    });

    test('initialize sends debug true when specified', () async {
      await VeonPixelTracker.initialize(
        baseUrl: 'https://example.com/pixel',
        debug: true,
      );

      expect(
        calls.single.arguments,
        {
          'baseUrl': 'https://example.com/pixel',
          'debug': true,
        },
      );
    });

    test('initialize throws on PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(
          code: 'INIT_FAILED',
          message: 'Server error',
        );
      });

      expect(
            () => VeonPixelTracker.initialize(
          baseUrl: 'https://example.com/pixel',
        ),
        throwsA(
          isA<Exception>().having(
                (e) => e.toString(),
            'message',
            contains('Failed to initialize'),
          ),
        ),
      );
    });

    test('isInitialized returns true', () async {
      final initialized = await VeonPixelTracker.isInitialized();

      expect(initialized, isTrue);
    });

    test('isInitialized returns false', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => false);

      final initialized = await VeonPixelTracker.isInitialized();

      expect(initialized, isFalse);
    });

    test('isInitialized throws on PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(code: 'ERROR');
      });

      expect(
            () => VeonPixelTracker.isInitialized(),
        throwsA(
          isA<Exception>().having(
                (e) => e.toString(),
            'message',
            contains('Failed to check initialization'),
          ),
        ),
      );
    });

    test('shutdown invokes native method', () async {
      await VeonPixelTracker.shutdown();

      expect(calls.single.method, 'shutdown');
    });

    test('shutdown throws on PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(code: 'ERROR');
      });

      expect(
            () => VeonPixelTracker.shutdown(),
        throwsA(
          isA<Exception>().having(
                (e) => e.toString(),
            'message',
            contains('Failed to shutdown'),
          ),
        ),
      );
    });

    test('events getter returns stream', () {
      expect(
        VeonPixelTracker.events,
        isA<Stream<Map<String, dynamic>>>(),
      );
    });

    test('events getter returns same stream instance', () {
      final first = VeonPixelTracker.events;
      final second = VeonPixelTracker.events;

      expect(identical(first, second), isTrue);
    });
  });
}