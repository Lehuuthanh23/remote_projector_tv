import 'package:flutter/services.dart';

class UsbService {
  static const platform = MethodChannel('com.example.usb/serial');
  static const platformCommand = MethodChannel('com.example.myapp/command');

  static const usbEventChannel = EventChannel('com.example.usb/event');

  Future<List<String>> getUsbPath() async {
    List<String> usbPath = [];
    var result = await platform.invokeMethod('getUsbPath');
    for (var path in result) {
      usbPath.add(path.toString());
    }
    return usbPath;
  }

  Future<void> getCommand() async {
    // List<String> usbPath = [];
    platform.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    print(call.method);
    switch (call.method) {
      case 'stopVideo':
        print("Received parameter from Kotlin: ${call.method}");
      // Trả về kết quả (nếu cần)
      default:
        throw MissingPluginException('Not implemented: ${call.method}');
    }
  }
}
