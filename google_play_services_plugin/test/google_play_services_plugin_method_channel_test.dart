import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_play_services_plugin/google_play_services_plugin_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelGooglePlayServicesPlugin platform = MethodChannelGooglePlayServicesPlugin();
  const MethodChannel channel = MethodChannel('google_play_services_plugin');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
