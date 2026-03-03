
import 'veon_pixel_tracker_flutter_platform_interface.dart';

class VeonPixelTrackerFlutter {
  Future<String?> getPlatformVersion() {
    return VeonPixelTrackerFlutterPlatform.instance.getPlatformVersion();
  }
}
