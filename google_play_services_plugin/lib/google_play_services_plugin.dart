
import 'google_play_services_plugin_platform_interface.dart';

class GooglePlayServicesPlugin {
  Future<String?> getPlatformVersion() {
    return GooglePlayServicesPluginPlatform.instance.getPlatformVersion();
  }
}
