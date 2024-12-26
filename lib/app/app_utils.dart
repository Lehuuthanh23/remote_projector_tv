import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../constants/api.dart';
import '../models/device/device_info_model.dart';
import '../models/device/device_model.dart';
import '../models/user/user.dart';
import '../request/device/device.request.dart';
import 'app_sp.dart';
import 'app_sp_key.dart';

class AppUtils {
  static const platformChannel = MethodChannel('com.example.usb/serial');
  static const channelRestart = MethodChannel('restart');

  /// Add base host to url
  static String createUrl(String toMerge) {
    return '${Api.hostApi}$toMerge';
  }

  /// Add base host and id user to url
  static String createUrlWithUserId(String toMerge, String userId) {
    return '${Api.hostApi}$toMerge$userId';
  }

  static Options createOptionsNoCookie() {
    return Options(
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    );
  }

  /// Check if device is connect to user
  static Future<bool> checkConnect() async {
    User currentUser = User.fromJson(jsonDecode(AppSP.get(AppSPKey.userInfo)));
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
      AppSP.set(AppSPKey.currentDevice, jsonEncode(devices.first.toJson()));
      return true;
    } else {
      return false;
    }
  }
}

Future<bool> isVideoUrlValid(String? url) async {
  if (url == null) return false;

  try {
    final dio = Dio();
    final response = await dio.head(url);

    if (response.statusCode == 200 &&
        response.headers['content-type'] != null) {
      final contentType = response.headers['content-type']!.first;
      return contentType.startsWith('video/');
    }
  } catch (_) {}

  return false;
}

Future<bool> isImageUrlValid(String? url) async {
  if (url == null) return false;

  try {
    final dio = Dio();
    final response = await dio.head(url);

    if (response.statusCode == 200 &&
        response.headers['content-type'] != null) {
      final contentType = response.headers['content-type']!.first;
      return contentType.startsWith('image/');
    }
  } catch (_) {}

  return false;
}

extension DateTimeStringExtension on String {
  bool isBeforeBuildDate(String dateB) {
    DateFormat format = DateFormat("dd/MM/yyyy HH:mm");

    DateTime dateTimeA = format.parse(this);
    DateTime dateTimeB = format.parse(dateB);

    return dateTimeA.isBefore(dateTimeB);
  }
}
