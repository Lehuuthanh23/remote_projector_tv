import 'package:flutter/services.dart';

class AlarmService {
  static const MethodChannel _channel = MethodChannel('com.example.play_box.wakeup');

  Future<void> setWakeUpAlarm(int delayInSeconds) async {
    try {
      print('vào setWakeUpAlarm');
      await _channel.invokeMethod('setWakeUpAlarm', {'delay': delayInSeconds});
    } on PlatformException catch (e) {
      print("Lỗi khi đặt alarm: ${e.message}");
    }
  }
}
