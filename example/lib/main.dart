import 'package:flutter/material.dart';
import 'package:veon_pixel_tracker_flutter/veon_pixel_tracker_flutter.dart';

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

    /// слушаем результат инициализации
    VeonPixelTracker.listenInitialization((status) {
      print("PixelTracker init status: $status");
    });

    /// запускаем SDK
    VeonPixelTracker.initialize(
      baseUrl: "https://prebid.veonadx.com/openrtb2/auction",
      debug: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Pixel Tracker Example'),
        ),
      ),
    );
  }
}