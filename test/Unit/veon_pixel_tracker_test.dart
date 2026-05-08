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
    group('initialize', () {
      test('calls initialize with baseUrl and debug=false by default', () async {
        await VeonPixelTracker.initialize(
          baseUrl: 'https://example.com/pixel',
        );

        expect(calls.length, 1);
        expect(calls.last.method, 'initialize');
        expect(calls.last.arguments['baseUrl'], 'https://example.com/pixel');
        expect(calls.last.arguments['debug'], false);
      });

      test('calls initialize with debug=true when specified', () async {
        await VeonPixelTracker.initialize(
          baseUrl: 'https://example.com/pixel',
          debug: true,
        );

        expect(calls.last.arguments['debug'], true);
      });

      test('throws on PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'INIT_FAILED', message: 'Server error');
        });

        expect(
              () => VeonPixelTracker.initialize(baseUrl: 'https://example.com/pixel'),
          throwsA(isA<Exception>().having(
                (e) => e.toString(),
            'message',
            contains('Failed to initialize'),
          )),
        );
      });
    });

    group('isInitialized', () {
      test('returns true when native side returns true', () async {
        final result = await VeonPixelTracker.isInitialized();
        expect(result, isTrue);
      });

      test('returns false when native side returns false', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async => false);

        final result = await VeonPixelTracker.isInitialized();
        expect(result, isFalse);
      });

      test('throws on PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'ERROR');
        });

        expect(
              () => VeonPixelTracker.isInitialized(),
          throwsA(isA<Exception>().having(
                (e) => e.toString(),
            'message',
            contains('Failed to check initialization'),
          )),
        );
      });
    });

    group('shutdown', () {
      test('calls shutdown method', () async {
        await VeonPixelTracker.shutdown();

        expect(calls.last.method, 'shutdown');
      });

      test('throws on PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'ERROR');
        });

        expect(
              () => VeonPixelTracker.shutdown(),
          throwsA(isA<Exception>().having(
                (e) => e.toString(),
            'message',
            contains('Failed to shutdown'),
          )),
        );
      });
    });

    group('events stream', () {
      test('events getter returns a stream', () {
        expect(VeonPixelTracker.events, isA<Stream<Map<String, dynamic>>>());
      });

      test('events getter returns same stream instance on repeated calls', () {
        final s1 = VeonPixelTracker.events;
        final s2 = VeonPixelTracker.events;
        expect(identical(s1, s2), isTrue);
      });
    });
  });
}
