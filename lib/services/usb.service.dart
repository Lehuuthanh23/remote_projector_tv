import 'package:flutter/services.dart';

class UsbService {
  static const platform = MethodChannel('com.example.usb/serial');
  static const usbEventChannel = EventChannel('com.example.usb/event');

  Future<List<String>> getUsbPath() async {
    List<String> usbPath = [];
    var result = await platform.invokeMethod('getUsbPath');
    for (var path in result) {
      usbPath.add(path.toString());
    }
    return usbPath;
  }
}
