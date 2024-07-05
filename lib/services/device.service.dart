import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:play_box/app/app_sp.dart';
import 'package:play_box/app/app_sp_key.dart';

import '../app/app_utils.dart';
import '../models/device/device_info_model.dart';

class DeviceInfoService {
  Future<DeviceInfoModel> getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    DeviceInfoModel deviceInfoModel;

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      String serialNumber = '';
      String? androidId = await getSerial();

      if (androidInfo.version.sdkInt < 29) {
        serialNumber = androidInfo.serialNumber;
      } else {
        serialNumber = 'unknown';
      }

      deviceInfoModel = DeviceInfoModel(
        model: androidInfo.model ?? '',
        manufacturer: androidInfo.manufacturer ?? '',
        osVersion: 'Android ${androidInfo.version.release}',
        deviceName: androidInfo.device ?? '',
        platform: 'Android',
        serialNumber: serialNumber,
        androidId: androidId ?? androidInfo.id,
        uuid: androidInfo.id,
      );
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceInfoModel = DeviceInfoModel(
        model: iosInfo.utsname.machine ?? '',
        manufacturer: 'Apple',
        osVersion: '${iosInfo.systemName} ${iosInfo.systemVersion}',
        deviceName: iosInfo.name ?? '',
        platform: 'iOS',
        serialNumber:
            iosInfo.identifierForVendor, // Sử dụng identifierForVendor (UUID)
        androidId: '', // Không áp dụng cho iOS
        uuid: iosInfo.identifierForVendor ?? '', // Trả về identifierForVendor
      );
    } else {
      deviceInfoModel = DeviceInfoModel(
        model: 'Unknown',
        manufacturer: 'Unknown',
        osVersion: 'Unknown',
        deviceName: 'Unknown',
        platform: 'Unknown',
        serialNumber: null,
        androidId: 'Unknown',
        uuid: 'Unknown',
      );
    }

    AppSP.set(AppSPKey.device, jsonEncode(deviceInfoModel.toJson()));
    return deviceInfoModel;
  }

  Future<String?> getSerial() async {
    try {
      String? serial = await AppUtils.platformChannel.invokeMethod('getSerial');
      print('serial: $serial');
      return serial;
    } on PlatformException catch (e) {
      print("Failed to get serial number: '${e.message}'.");
      return null;
    }
  }
}
