import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'google_play_services_plugin_method_channel.dart';

abstract class GooglePlayServicesPluginPlatform extends PlatformInterface {
  /// Constructs a GooglePlayServicesPluginPlatform.
  GooglePlayServicesPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static GooglePlayServicesPluginPlatform _instance = MethodChannelGooglePlayServicesPlugin();

  /// The default instance of [GooglePlayServicesPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelGooglePlayServicesPlugin].
  static GooglePlayServicesPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [GooglePlayServicesPluginPlatform] when
  /// they register themselves.
  static set instance(GooglePlayServicesPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
