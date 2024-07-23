import 'package:flutter_test/flutter_test.dart';
import 'package:google_play_services_plugin/google_play_services_plugin.dart';
import 'package:google_play_services_plugin/google_play_services_plugin_platform_interface.dart';
import 'package:google_play_services_plugin/google_play_services_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGooglePlayServicesPluginPlatform
    with MockPlatformInterfaceMixin
    implements GooglePlayServicesPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final GooglePlayServicesPluginPlatform initialPlatform = GooglePlayServicesPluginPlatform.instance;

  test('$MethodChannelGooglePlayServicesPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelGooglePlayServicesPlugin>());
  });

  test('getPlatformVersion', () async {
    GooglePlayServicesPlugin googlePlayServicesPlugin = GooglePlayServicesPlugin();
    MockGooglePlayServicesPluginPlatform fakePlatform = MockGooglePlayServicesPluginPlatform();
    GooglePlayServicesPluginPlatform.instance = fakePlatform;

    expect(await googlePlayServicesPlugin.getPlatformVersion(), '42');
  });
}
