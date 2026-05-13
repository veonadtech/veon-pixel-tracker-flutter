import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veon_pixel_tracker_flutter/src/widgets/pixel_tracker_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PixelTrackerView', () {
    testWidgets('renders with provided pixel size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PixelTrackerView(pixelId: 'test_pixel', pixelSize: 40),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(PixelTrackerView),
          matching: find.byType(SizedBox),
        ),
      );

      expect(sizedBox.width, 40.0);
      expect(sizedBox.height, 40.0);
    });

    testWidgets('defaults pixel size to 1', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PixelTrackerView(pixelId: 'test_pixel')),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(PixelTrackerView),
          matching: find.byType(SizedBox),
        ),
      );

      expect(sizedBox.width, 1.0);
      expect(sizedBox.height, 1.0);
    });

    testWidgets('disposes without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PixelTrackerView(pixelId: 'dispose_test')),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );

      expect(find.byType(PixelTrackerView), findsNothing);
    });
  });
}
