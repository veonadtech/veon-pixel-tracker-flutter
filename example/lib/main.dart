import 'package:flutter/material.dart';
import 'package:veon_pixel_tracker_flutter/veon_pixel_tracker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();

    VeonPixelTracker.events.listen((event) {

      if (event["event"] == "initialized") {

        if (event["status"] == "success") {
          print("PixelTracker initialized");
        } else {
          print("PixelTracker failed: ${event["message"]}");
        }

      }
    });

    VeonPixelTracker.initialize(
      baseUrl: "https://pixel-tracker.veonadtech.com/v1/pixel-event",
      debug: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text("PixelTracker Demo")),
      ),
    );
  }
}