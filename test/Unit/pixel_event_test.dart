import 'package:flutter_test/flutter_test.dart';
import 'package:veon_pixel_tracker_flutter/src/models/pixel_event.dart';

void main() {
  group('PixelEvent', () {
    test('fromMap parses appearance event', () {
      final event = PixelEvent.fromMap({
        'type': 'appearance',
        'timestamp': '2024-01-01T10:00:00Z',
        'error': null,
      });

      expect(event.type, 'appearance');
      expect(event.timestamp, '2024-01-01T10:00:00Z');
      expect(event.error, isNull);
    });

    test('fromMap parses error event', () {
      final event = PixelEvent.fromMap({
        'type': 'error',
        'timestamp': '2024-01-01T10:00:00Z',
        'error': 'Network timeout',
      });

      expect(event.type, 'error');
      expect(event.error, 'Network timeout');
    });

    test('isAppearance true only for appearance', () {
      final event = PixelEvent('appearance', '2024-01-01T10:00:00Z');

      expect(event.isAppearance, isTrue);
      expect(event.isDisappearance, isFalse);
      expect(event.isRefresh, isFalse);
      expect(event.isError, isFalse);
    });

    test('isDisappearance true only for disappearance', () {
      final event = PixelEvent('disappearance', '2024-01-01T10:00:00Z');

      expect(event.isAppearance, isFalse);
      expect(event.isDisappearance, isTrue);
      expect(event.isRefresh, isFalse);
      expect(event.isError, isFalse);
    });

    test('isRefresh true only for refresh', () {
      final event = PixelEvent('refresh', '2024-01-01T10:00:00Z');

      expect(event.isAppearance, isFalse);
      expect(event.isDisappearance, isFalse);
      expect(event.isRefresh, isTrue);
      expect(event.isError, isFalse);
    });

    test('isError true only for error', () {
      final event = PixelEvent(
        'error',
        '2024-01-01T10:00:00Z',
        'Something failed',
      );

      expect(event.isAppearance, isFalse);
      expect(event.isDisappearance, isFalse);
      expect(event.isRefresh, isFalse);
      expect(event.isError, isTrue);
    });

    test('all flags false for unknown type', () {
      final event = PixelEvent('unknown', '2024-01-01T10:00:00Z');

      expect(event.isAppearance, isFalse);
      expect(event.isDisappearance, isFalse);
      expect(event.isRefresh, isFalse);
      expect(event.isError, isFalse);
    });
  });
}
