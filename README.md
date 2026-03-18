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
  pixel_tracker_flutter:
    git:
      url: git@github.com:veonadtech/veon-pixel-tracker-flutter.git
      ref: 0.1.0
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
baseUrl: 'https://your-pixel-tracker-url.com/v1/pixel-event',
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
    switch (event['event']) {
      case 'initialized':
        print('SDK initialized: ${event['data']}');
        break;
      case 'pixel_event':
        final data = event['data'];
        print('Pixel ${data['pixelId']}: ${data['type']} at ${data['timestamp']}');
        break;
    }
  });
}
```

### Create a Pixel Widget
```dart
import 'package:veon_pixel_tracker_flutter/veon_pixel_tracker.dart';

class MyPixelScreen extends StatelessWidget {
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
                      pixelSize: 40, // 40x40 pixel for debug mode
                      visibilityThreshold: 30, // 30px visibility required
                      color: '#FF0000', // Red color
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
}
```
### Programmatic Pixel Control
``` dart
class PixelController extends StatefulWidget {
  @override
  _PixelControllerState createState() => _PixelControllerState();
}

class _PixelControllerState extends State<PixelController> {
  PixelHandle? _pixelHandle;
  PixelStats? _stats;
  int _refreshTime = 5;

  @override
  void initState() {
    super.initState();
    _createPixel();
  }

  Future<void> _createPixel() async {
    _pixelHandle = await VeonPixelTracker.createPixel(
      pixelId: 'controlled_pixel',
      refreshTimeSeconds: _refreshTime,
      pixelSize: 50,
      visibilityThreshold: 25,
      color: '#00FF00',
    );

    // Set visibility check interval. The default value is 3 seconds.
    await _pixelHandle?.setVisibilityCheckInterval(3); 
    
    // Start tracking
    await _pixelHandle?.start();
    
    // Get initial stats
    _updateStats();
  }

  Future<void> _updateStats() async {
    if (_pixelHandle != null) {
      setState(() {
        _stats = await _pixelHandle!.getStats();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Appearances: ${_stats?.totalAppearances ?? 0}'),
        Text('Visible: ${_stats?.isCurrentlyVisible ?? false}'),
        
        Row(
          children: [
            ElevatedButton(
              onPressed: () => _pixelHandle?.start(),
              child: Text('Start'),
            ),
            ElevatedButton(
              onPressed: () => _pixelHandle?.stop(),
              child: Text('Stop'),
            ),
            ElevatedButton(
              onPressed: () {
                _pixelHandle?.updateRefreshTime(++_refreshTime);
                _updateStats();
              },
              child: Text('Increase Refresh'),
            ),
          ],
        ),
      ],
    );
  }
}
```

## Complete Example
- Check out the /example folder for a complete working example with:
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
- createPixel({...}) - Create a new pixel programmatically
- events - Stream of SDK events

### PixelHandle
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


## License
* This project is licensed under the BSD 3-Clause License - see the LICENSE file for details.

## Support
* Issues: [GitHub Issues](https://github.com/veonadtech/veon-pixel-tracker-flutter)


## About Veon
* Veon provides cutting-edge advertising technology solutions. Visit [veonadtech.com](https://veonadtech.com/en) to learn more.