import 'package:disk_space_plus/disk_space_plus.dart';

import '../../app/app_utils.dart';

class UsbService {
  Future<List<String>> getUsbPath() async {
    List<String> usbPath = [];
    var result = await AppUtils.platformChannel.invokeMethod('getUsbPath');
    for (var path in result) {
      double? freeDiskSpaceMB =
          await DiskSpacePlus.getFreeDiskSpaceForPath(path);
      if (freeDiskSpaceMB != null && freeDiskSpaceMB > 0) {
        usbPath.add(path.toString());
      }
    }
    return usbPath;
  }
}
