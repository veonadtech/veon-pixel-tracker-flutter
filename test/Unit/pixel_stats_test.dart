import 'package:flutter_test/flutter_test.dart';
import 'package:veon_pixel_tracker_flutter/src/models/pixel_stats.dart';

void main() {
  group('PixelStats', () {
    group('fromMap', () {
      test('parses all fields correctly', () {
        final map = {
          'totalAppearances': 5,
          'isCurrentlyVisible': true,
          'refreshEnabled': true,
          'nextRefreshInMs': 3000,
        };
        final stats = PixelStats.fromMap(map);

        expect(stats.totalAppearances, 5);
        expect(stats.isCurrentlyVisible, isTrue);
        expect(stats.refreshEnabled, isTrue);
        expect(stats.nextRefreshInMs, 3000);
      });

      test('parses zero values correctly', () {
        final map = {
          'totalAppearances': 0,
          'isCurrentlyVisible': false,
          'refreshEnabled': false,
          'nextRefreshInMs': 0,
        };
        final stats = PixelStats.fromMap(map);

        expect(stats.totalAppearances, 0);
        expect(stats.isCurrentlyVisible, isFalse);
        expect(stats.refreshEnabled, isFalse);
        expect(stats.nextRefreshInMs, 0);
      });

      test('parses large appearance count', () {
        final map = {
          'totalAppearances': 9999,
          'isCurrentlyVisible': true,
          'refreshEnabled': true,
          'nextRefreshInMs': 60000,
        };
        final stats = PixelStats.fromMap(map);
        expect(stats.totalAppearances, 9999);
      });
    });

    group('nextRefreshInSeconds', () {
      test('converts ms to seconds correctly', () {
        final stats = PixelStats.fromMap({
          'totalAppearances': 0,
          'isCurrentlyVisible': false,
          'refreshEnabled': true,
          'nextRefreshInMs': 5000,
        });
        expect(stats.nextRefreshInSeconds, 5);
      });

      test('rounds up fractional seconds', () {
        final stats = PixelStats.fromMap({
          'totalAppearances': 0,
          'isCurrentlyVisible': false,
          'refreshEnabled': true,
          'nextRefreshInMs': 1500,
        });
        expect(stats.nextRefreshInSeconds, 2);
      });

      test('rounds down fractional seconds below 0.5', () {
        final stats = PixelStats.fromMap({
          'totalAppearances': 0,
          'isCurrentlyVisible': false,
          'refreshEnabled': true,
          'nextRefreshInMs': 1400,
        });
        expect(stats.nextRefreshInSeconds, 1);
      });

      test('returns 0 when nextRefreshInMs is 0', () {
        final stats = PixelStats.fromMap({
          'totalAppearances': 0,
          'isCurrentlyVisible': false,
          'refreshEnabled': false,
          'nextRefreshInMs': 0,
        });
        expect(stats.nextRefreshInSeconds, 0);
      });
    });
  });
}
