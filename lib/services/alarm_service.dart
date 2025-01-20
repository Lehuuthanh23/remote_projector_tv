import 'package:flutter/services.dart';

class AlarmService {
  static const MethodChannel _channel =
      MethodChannel('com.example.play_box.wakeup');

  Future<void> setWakeUpAlarm(int delayInSeconds) async {
    try {
      print('vào setWakeUpAlarm');
      await _channel.invokeMethod('setWakeUpAlarm', {'delay': delayInSeconds});
    } on PlatformException catch (e) {
      print("Lỗi khi đặt alarm: ${e.message}");
    }
  }

  void listenForWakeUpEvents(Function onDeviceWokenUp) {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == "onDeviceWokenUp") {
        // Nhận kết quả khi thiết bị thức dậy
        print(call.arguments); // "Device has been woken up!"
        onDeviceWokenUp();
        // Bạn có thể thực hiện các hành động sau khi nhận được thông báo
      }
    });
  }
}
