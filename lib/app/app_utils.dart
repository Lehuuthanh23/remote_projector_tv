import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../constants/api.dart';
import '../models/device/device_info_model.dart';
import '../models/device/device_model.dart';
import '../models/user/user.dart';
import '../request/device/device.request.dart';
import 'app_sp.dart';
import 'app_sp_key.dart';

class AppUtils {
  static const platformChannel = MethodChannel('com.example.usb/serial');

  //http url
  static String createUrl(String toMerge) {
    return '${Api.hostApi}$toMerge';
  }

  static String createUrlWithUserId(String toMerge, String userId) {
    return '${Api.hostApi}$toMerge$userId';
  }

  //option when send api
  static Options createOptionsWithCookie(String cookieData) {
    return Options(
      headers: {
        'Cookie': 'PHPSESSID=$cookieData',
        'Content-Type': 'multipart/form-data',
      },
    );
  }

  static Options createOptionsNoCookie() {
    return Options(
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    );
  }

  static Future<bool> checkConnect() async {
    User currentUser = User.fromJson(jsonDecode(AppSP.get(AppSPKey.user_info)));
    DeviceInfoModel deviceInfoModel =
        DeviceInfoModel.fromJson(jsonDecode(AppSP.get(AppSPKey.device)));
    DeviceRequest deviceRequest = DeviceRequest();
    List<Device> lstDevice =
        await deviceRequest.getDeviceByCustomerId(currentUser.customerId!);
    List<Device> devices = lstDevice
        .where((device) =>
            device.serialComputer ==
            (deviceInfoModel.serialNumber == 'unknown'
                ? deviceInfoModel.androidId
                : deviceInfoModel.serialNumber))
        .toList();
    if (devices.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }
  //get user id
  // static Future<String> getUserIdFromLocal() async {
  //   var storedUserInfo = await AppSP.retrieveItem(AppSPKey.user_info);
  //   if (storedUserInfo != null) {
  //     final User userData = User.fromJson(storedUserInfo);
  //     return userData.customerId ?? "";
  //   } else {
  //     return "";
  //   }
  // }
}
