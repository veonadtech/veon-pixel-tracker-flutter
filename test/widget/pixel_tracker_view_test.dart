import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veon_pixel_tracker_flutter/src/widgets/pixel_tracker_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PixelTrackerView', () {
    // AndroidView does not render in host-side (VM) widget tests —
    // only the SizedBox wrapper and widget tree are verifiable here.

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PixelTrackerView(
              pixelId: 'test_pixel',
              pixelSize: 40,
            ),
          ),
        ),
      );
      expect(find.byType(PixelTrackerView), findsOneWidget);
    });

    testWidgets('SizedBox has correct size from pixelSize', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PixelTrackerView(
              pixelId: 'test_pixel',
              pixelSize: 40,
            ),
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

    testWidgets('SizedBox defaults to pixelSize = 1', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PixelTrackerView(pixelId: 'test_pixel'),
          ),
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

    testWidgets('widget field values are set correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PixelTrackerView(
              pixelId: 'fields_test',
              refreshTimeSeconds: 10,
              pixelSize: 20,
              visibilityThreshold: 50,
              color: '#00FF00',
            ),
          ),
        ),
      );

      final widget = tester.widget<PixelTrackerView>(
        find.byType(PixelTrackerView),
      );
      expect(widget.pixelId, 'fields_test');
      expect(widget.refreshTimeSeconds, 10);
      expect(widget.pixelSize, 20);
      expect(widget.visibilityThreshold, 50);
      expect(widget.color, '#00FF00');
    });

    testWidgets('accepts optional color param without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PixelTrackerView(
              pixelId: 'color_test',
              color: '#FF0000',
            ),
          ),
        ),
      );
      expect(find.byType(PixelTrackerView), findsOneWidget);
    });

    testWidgets('onPixelCreated and onEvent callbacks wire without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PixelTrackerView(
              pixelId: 'cb_test',
              onPixelCreated: (_) {},
              onEvent: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(PixelTrackerView), findsOneWidget);
    });

    testWidgets('disposes without error on unmount', (tester) async {
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
