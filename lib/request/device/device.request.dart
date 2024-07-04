import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:play_box/app/app_sp.dart';
import 'package:play_box/app/app_sp_key.dart';
import 'package:play_box/models/device/device_model.dart';
import 'package:play_box/models/notification/notify_model.dart';

import '../../app/app_utils.dart';
import '../../constants/api.dart';
import '../../models/device/device_info_model.dart';
import '../../models/user/user.dart';
import '../notification/notify.request.dart';

class DeviceRequest {
  final Dio dio = Dio();

  Future<bool> connectDevice(
      DeviceInfoModel deviceInfo, User currentUser) async {
    bool checkConnect = false;
    final formData = FormData.fromMap({
      'computer_name': deviceInfo.model,
      'seri_computer': deviceInfo.serialNumber == 'unknown'
          ? deviceInfo.androidId
          : deviceInfo.serialNumber,
      'status': '1',
      'provinces': '',
      'district': '',
      'wards': '',
      'center_id': '5',
      'location': '',
      'customer_id': currentUser.customerId,
      'type': 'chia sẻ',
      'id_dir': '',
      'time_end': ''
    });
    try {
      final response = await dio.post(
        AppUtils.createUrl(Api.createDevice),
        data: formData,
        options: AppUtils.createOptionsNoCookie(),
      );
      print('Body thêm device: ${response.data}');
      final responseData = jsonDecode(response.data);
      if (responseData["status"] == 1) {
        checkConnect = true;

        //Lưu thiết bị vào bộ nhớ khi kết nối thành công
        DeviceInfoModel deviceInfoModel =
            DeviceInfoModel.fromJson(jsonDecode(AppSP.get(AppSPKey.device)));
        DeviceRequest deviceRequest = DeviceRequest();
        List<Device> lstDevice =
            await deviceRequest.getDeviceByCustomerId(currentUser.customerId!);
        Device? device = lstDevice
            .where((device) =>
                device.serialComputer ==
                (deviceInfoModel.serialNumber == 'unknown'
                    ? deviceInfoModel.androidId
                    : deviceInfoModel.serialNumber))
            .toList()
            .first;
        //Thêm thông báo
        NotifyRequest notifyRequest = NotifyRequest();
        Notify notify = Notify(
            title: 'Kết nối thiết bị mới',
            descript: 'Kết nối thiết bị mới thành công',
            detail: 'Thiết bị ${deviceInfo.model} được thêm thành công',
            picture: '');
        await notifyRequest.addNotify(notify);
        //
        AppSP.set(AppSPKey.computer, jsonEncode(device.toJson()));

        await AppUtils.platformChannel.invokeMethod('saveComputer', {
          AppSPKey.serial_computer: device.serialComputer,
          AppSPKey.computer_id: device.computerId
        });
        //
      } else {
        print('Lỗi khi thêm device: ${response.data}');
        checkConnect = false;
      }
    } catch (e) {
      print('Lỗi: $e');
    }
    return checkConnect;
  }

  Future<List<Device>> getDeviceByCustomerId(String customerId) async {
    List<Device> lstAllDevice = [];
    final response = await dio.get(
      '${Api.hostApi}${Api.getDeviceByCustomerId}/$customerId',
    );
    final responseData = jsonDecode(response.data);
    List<dynamic> deviceList = responseData['Device_list'];
    if (deviceList.isNotEmpty) {
      lstAllDevice = deviceList.map((e) => Device.fromJson(e)).toList();
    }
    return lstAllDevice;
  }
}
