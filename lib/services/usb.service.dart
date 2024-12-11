import '../../app/app_utils.dart';

class UsbService {
  Future<List<String>> getUsbPath() async {
    List<String> usbPath = [];
    var result = await AppUtils.platformChannel.invokeMethod('getUsbPath');
    for (var path in result) {
      usbPath.add(path.toString());
    }
    return usbPath;
  }
}
