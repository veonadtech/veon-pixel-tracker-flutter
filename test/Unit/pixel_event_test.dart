import 'package:flutter_test/flutter_test.dart';
import 'package:veon_pixel_tracker_flutter/src/models/pixel_event.dart';

void main() {
  group('PixelEvent', () {
    group('fromMap', () {
      test('creates event with all fields', () {
        final map = {
          'type': 'appearance',
          'timestamp': '2024-01-01T10:00:00Z',
          'error': null,
        };
        final event = PixelEvent.fromMap(map);

        expect(event.type, 'appearance');
        expect(event.timestamp, '2024-01-01T10:00:00Z');
        expect(event.error, isNull);
      });

      test('creates error event with error message', () {
        final map = {
          'type': 'error',
          'timestamp': '2024-01-01T10:00:00Z',
          'error': 'Network timeout',
        };
        final event = PixelEvent.fromMap(map);

        expect(event.type, 'error');
        expect(event.error, 'Network timeout');
      });
    });

    group('type flags', () {
      test('isAppearance returns true for appearance type', () {
        final event = PixelEvent('appearance', '2024-01-01T10:00:00Z');
        expect(event.isAppearance, isTrue);
        expect(event.isDisappearance, isFalse);
        expect(event.isRefresh, isFalse);
        expect(event.isError, isFalse);
      });

      test('isDisappearance returns true for disappearance type', () {
        final event = PixelEvent('disappearance', '2024-01-01T10:00:00Z');
        expect(event.isDisappearance, isTrue);
        expect(event.isAppearance, isFalse);
        expect(event.isRefresh, isFalse);
        expect(event.isError, isFalse);
      });

      test('isRefresh returns true for refresh type', () {
        final event = PixelEvent('refresh', '2024-01-01T10:00:00Z');
        expect(event.isRefresh, isTrue);
        expect(event.isAppearance, isFalse);
        expect(event.isDisappearance, isFalse);
        expect(event.isError, isFalse);
      });

      test('isError returns true for error type', () {
        final event = PixelEvent('error', '2024-01-01T10:00:00Z', 'Something went wrong');
        expect(event.isError, isTrue);
        expect(event.isAppearance, isFalse);
        expect(event.isDisappearance, isFalse);
        expect(event.isRefresh, isFalse);
      });

      test('all flags false for unknown type', () {
        final event = PixelEvent('unknown', '2024-01-01T10:00:00Z');
        expect(event.isAppearance, isFalse);
        expect(event.isDisappearance, isFalse);
        expect(event.isRefresh, isFalse);
        expect(event.isError, isFalse);
      });
    });
  });
}
