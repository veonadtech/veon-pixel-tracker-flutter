import 'package:flutter_test/flutter_test.dart';
import 'package:veon_pixel_tracker_flutter/src/models/pixel_stats.dart';

void main() {
  group('PixelStats', () {
    test('fromMap parses values correctly', () {
      final stats = PixelStats.fromMap({
        'totalAppearances': 5,
        'isCurrentlyVisible': true,
        'refreshEnabled': true,
        'nextRefreshInMs': 3000,
      });

      expect(stats.totalAppearances, 5);
      expect(stats.isCurrentlyVisible, isTrue);
      expect(stats.refreshEnabled, isTrue);
      expect(stats.nextRefreshInMs, 3000);
    });

    test('fromMap parses zero values correctly', () {
      final stats = PixelStats.fromMap({
        'totalAppearances': 0,
        'isCurrentlyVisible': false,
        'refreshEnabled': false,
        'nextRefreshInMs': 0,
      });

      expect(stats.totalAppearances, 0);
      expect(stats.isCurrentlyVisible, isFalse);
      expect(stats.refreshEnabled, isFalse);
      expect(stats.nextRefreshInMs, 0);
    });

    test('nextRefreshInSeconds converts milliseconds', () {
      final stats = PixelStats.fromMap({
        'totalAppearances': 0,
        'isCurrentlyVisible': false,
        'refreshEnabled': true,
        'nextRefreshInMs': 5000,
      });

      expect(stats.nextRefreshInSeconds, 5);
    });

    test('nextRefreshInSeconds rounds correctly', () {
      final stats = PixelStats.fromMap({
        'totalAppearances': 0,
        'isCurrentlyVisible': false,
        'refreshEnabled': true,
        'nextRefreshInMs': 1500,
      });

      expect(stats.nextRefreshInSeconds, 2);
    });

    test('nextRefreshInSeconds returns zero for zero milliseconds', () {
      final stats = PixelStats.fromMap({
        'totalAppearances': 0,
        'isCurrentlyVisible': false,
        'refreshEnabled': false,
        'nextRefreshInMs': 0,
      });

      expect(stats.nextRefreshInSeconds, 0);
    });
  });
}
