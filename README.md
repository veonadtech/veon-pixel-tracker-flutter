# Veon Pixel Tracker Flutter
* Flutter plugin for Veon Pixel Tracker SDK. 
* This plugin allows you to track pixel visibility events in your Flutter applications with 
* the same functionality as the native Android SDK.

## Features
- ✅ Initialize Pixel Tracker SDK with custom configuration
- ✅ Create and manage tracking pixels
- ✅ Real-time visibility events (appearance, disappearance, refresh)
- ✅ Platform View integration for native rendering
- ✅ Comprehensive statistics and monitoring
- ✅ Full control over refresh intervals and visibility thresholds

## Requirements
* Flutter version at least `3.32.8`
### Android
* `minSdkVersion` at least `21`
* `compileSdkVersion` at least `33`
* `Java Version` at least `11`
* 'Kotlin Version' at least `1.8.0'
### iOS
* not implemented yet


## Installation
* Add this to your package's `pubspec.yaml` file:
```yaml
dependencies:
  veon_pixel_tracker_flutter:
    git:
      url: git@github.com:veonadtech/veon-pixel-tracker-flutter.git
      ref: 0.2.0 // replace with the version you want to use
```


## Platform Support
- Android ✅
- iOS ⬜ (Coming soon)

## Quick Start

### Initialize the SDK
```dart
import 'package:veon_pixel_tracker_flutter/veon_pixel_tracker.dart';

void main() {
runApp(MyApp());
}

class MyApp extends StatefulWidget {
@override
_MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeTracker();
  }

  Future<void> _initializeTracker() async {
    try {
      await VeonPixelTracker.initialize(
        baseUrl: 'Enter your base URL here',
        debug: true, // Set to false in production
      );
      if (await VeonPixelTracker.isInitialized()) {
        print('✅ PixelTracker initialized successfully');
      }
    } catch (e) {
      print('❌ Initialization failed: $e');
    }
  }
}
```

### Listen to SDK Events
```dart
@override
void initState() {
  super.initState();
  
  VeonPixelTracker.events.listen((event) {
    final eventType = event['event'];
    final data = event['data'];

    switch (eventType) {
      case 'initialized':
        print('SDK initialized: $data');
        break;
      case 'pixel_event':
        print('Pixel ${data['pixelId']}: ${data['type']} at ${data['timestamp']}');
        break;
    }
  });
}
```

### Create a Pixel Widget
```dart
import 'package:veon_pixel_tracker_flutter/veon_pixel_tracker.dart';

class MyPixelScreen extends StatefulWidget {
  @override
  _MyPixelScreenState createState() => _MyPixelScreenState();
}

class _MyPixelScreenState extends State<MyPixelScreen> {
  PixelController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Your content here...
            
            // Pixel positioned off-screen (requires scrolling)
            Container(
              height: MediaQuery.of(context).size.height * 2,
              child: Stack(
                children: [
                  Positioned(
                    top: MediaQuery.of(context).size.height * 1.5,
                    left: MediaQuery.of(context).size.width / 2 - 20,
                    child: PixelTrackerView(
                      pixelId: 'home_screen_pixel',
                      refreshTimeSeconds: 5, // Refresh every 5 seconds
                      pixelSize: 40, // 40x40 for debug, 1x1 for release
                      visibilityThreshold: 1, // 1px visibility required
                      color: '#FF0000', // Red color
                      onPixelCreated: (controller) {
                        _controller = controller;
                        controller.setVisibilityCheckInterval(3);
                        controller.start();
                      },
                      onEvent: (event) {
                        if (event.isAppearance) {
                          print('✅ Pixel visible!');
                        } else if (event.isDisappearance) {
                          print('👻 Pixel hidden');
                        } else if (event.isRefresh) {
                          print('🔄 Pixel refreshed');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.destroy();
    super.dispose();
  }
}
```

### Pixel Control with Controller
```dart 
class PixelControllerExample extends StatefulWidget {
  @override
  _PixelControllerExampleState createState() => _PixelControllerExampleState();
}

class _PixelControllerExampleState extends State<PixelControllerExample> {
  PixelController? _controller;
  PixelStats? _stats;
  int _refreshTime = 5;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_stats != null) ...[
          Text('Appearances: ${_stats!.totalAppearances}'),
          Text('Visible: ${_stats!.isCurrentlyVisible ? "Yes" : "No"}'),
        ],

        Row(
          children: [
            ElevatedButton(
              onPressed: () => _controller?.start(),
              child: Text('Start'),
            ),
            ElevatedButton(
              onPressed: () => _controller?.stop(),
              child: Text('Stop'),
            ),
            ElevatedButton(
              onPressed: () {
                _controller?.updateRefreshTime(++_refreshTime);
                _updateStats();
              },
              child: Text('Increase Refresh'),
            ),
          ],
        ),

        PixelTrackerView(
          pixelId: 'controlled_pixel',
          refreshTimeSeconds: _refreshTime,
          pixelSize: 50,
          visibilityThreshold: 25,
          color: '#00FF00',
          onPixelCreated: (controller) {
            _controller = controller;
            controller.setVisibilityCheckInterval(3);
            controller.start();
          },
          onEvent: (event) {
            if (event.isAppearance) _updateStats();
          },
        ),
      ],
    );
  }

  Future<void> _updateStats() async {
    if (_controller != null) {
      final stats = await _controller!.getStats();
      setState(() => _stats = stats);
    }
  }

  @override
  void dispose() {
    _controller?.destroy();
    super.dispose();
  }
}
```

## Complete Example
Check out the /example folder for a complete working example with:
- SDK initialization
- Pixel creation with custom positioning
- Real-time event logging
- Statistics display
- Interactive controls


## API Reference

### VeonPixelTracker
- initialize({required String baseUrl, bool debug}) - Initialize the SDK
- isInitialized() - Check if SDK is initialized
- shutdown() - Shutdown SDK and cleanup
- events - Stream of SDK events

### PixelController
- start() - Start tracking the pixel
- stop() - Stop tracking
- destroy() - Destroy pixel and cleanup
- updateRefreshTime(int seconds) - Change refresh interval
- setVisibilityCheckInterval(int seconds) - Set how often to check visibility
- getStats() - Get current statistics

### PixelStats
- totalAppearances - Total number of times pixel appeared
- isCurrentlyVisible - Current visibility status
- refreshEnabled - Whether refresh is enabled
- nextRefreshInMs - Milliseconds until next refresh
- nextRefreshInSeconds - Seconds until next refresh

### PixelEvent
- type - Event type (appearance/disappearance/refresh/error)
- timestamp - Event timestamp
- error - Error message (if type is error)
- isAppearance - True if appearance event
- isDisappearance - True if disappearance event
- isRefresh - True if refresh event
- isError - True if error event


## Troubleshooting

### Common Issues

#### SDK not initialized
- Ensure initialize() is called before creating pixels
- Check that baseUrl is correct and accessible

#### Pixel not appearing
- Verify pixel is positioned within scrollable area
- Check pixel size is visible (>1px)
- Ensure visibility threshold is appropriate

#### Events not firing
- Confirm SDK is initialized
- Check that start() was called on the pixel
- Verify visibility check interval is set


## Debug Logs
* Enable debug mode during initialization:

```dart
VeonPixelTracker.initialize(
baseUrl: '...',
debug: true, // Enables detailed logging
);
```

## Support
* Issues: [GitHub Issues](https://github.com/veonadtech/veon-pixel-tracker-flutter)


## About Veon
* Veon provides cutting-edge advertising technology solutions. Visit [veonadtech.com](https://veonadtech.com/en) to learn more.