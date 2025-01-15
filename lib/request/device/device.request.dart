import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../app/app_sp.dart';
import '../../app/app_sp_key.dart';
import '../../app/app_utils.dart';
import '../../constants/api.dart';
import '../../models/device/device_info_model.dart';
import '../../models/device/device_model.dart';
import '../../models/notification/notify_model.dart';
import '../../models/user/user.dart';
import '../notification/notify.request.dart';

class DeviceRequest {
  final Dio _dio = Dio();

  Future updateRomDevice(
      String computerId, String romMemoryTotal, String romMemoryUsed) async {
    final formData = FormData.fromMap({
      'rom_memory_total': romMemoryTotal,
      'rom_memory_used': romMemoryUsed,
    });
    final response = await _dio.post(
      AppUtils.createUrl('${Api.updateRomMemory}/$computerId'),
      data: formData,
      options: AppUtils.createOptionsNoCookie(),
    );
    print('Response update rom: ${response.data}');
  }

  Future connectDevice(DeviceInfoModel deviceInfo, User currentUser) async {
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
      'type': 'chủ sở hữu',
      'id_dir': int.parse(AppSP.get(AppSPKey.currentDir).toString()),
      'time_end': ''
    });

    try {
      formData.fields.forEach((field) {
        print("${field.key}: ${field.value}");
      });

      final response = await _dio.post(
        AppUtils.createUrl(Api.createDevice),
        data: formData,
        options: AppUtils.createOptionsNoCookie(),
      );
      print(response);
      final responseData = jsonDecode(response.data);
      if (responseData["status"] == 1) {
        checkConnect = true;
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

        Notify notify = Notify(
            title: 'Kết nối thiết bị mới',
            descript: 'Kết nối thiết bị mới thành công',
            detail: 'Thiết bị ${deviceInfo.model} được thêm thành công',
            picture: '');
        await NotifyRequest().addNotify(notify);
        await AppSP.set(AppSPKey.currentDevice, jsonEncode(device.toJson()));
        await AppSP.set(AppSPKey.computer, jsonEncode(device.toJson()));
        await AppUtils.platformChannel.invokeMethod('saveComputer', {
          AppSPKey.serialComputer: device.serialComputer,
          AppSPKey.computerId: device.computerId
        });
        return checkConnect;
      } else {
        return responseData;
      }
    } catch (_) {}
  }

  Future<List<Device>> getDeviceByCustomerId(String customerId) async {
    List<Device> lstAllDevice = [];

    try {
      final response = await _dio.get(
        '${Api.hostApi}${Api.getDeviceByCustomerId}/$customerId',
      );

      final responseData = jsonDecode(response.data);
      // print(responseData);
      List<dynamic> deviceList = responseData['Device_list'];
      if (deviceList.isNotEmpty) {
        lstAllDevice = deviceList.map((e) => Device.fromJson(e)).toList();
      }
    } catch (_) {}

    return lstAllDevice;
  }

  Future<void> updateDeviceFirebaseToken(String token) async {
    String? deviceString = AppSP.get(AppSPKey.computer);

    if (!deviceString.isEmptyOrNull) {
      try {
        Device device = Device.fromJson(jsonDecode(deviceString!));
        // print(
        //     '${Api.hostApi}${Api.updateDeviceFirebaseToken}/${device.computerId}/$token');

        await _dio.get(
          '${Api.hostApi}${Api.updateDeviceFirebaseToken}/${device.computerId}/$token',
        );
      } catch (_) {}
    }
  }

  Future<bool> updateDirByDevice(Device device, int? idDir) async {
    device.idDir = idDir.toString();
    final formData = FormData.fromMap({
      'computer_name': device.computerName,
      'seri_computer': device.serialComputer,
      'status': device.status,
      'provinces': device.provinces,
      'district': device.district,
      'wards': device.wards,
      'center_id': device.centerId,
      'location': device.location,
      'customer_id': device.customerId,
      'type': device.type,
      'id_dir': device.idDir,
      'time_end': device.timeEnd,
    });

    try {
      final response = await _dio.post(
        AppUtils.createUrl('${Api.updateDevice}/${device.computerId}'),
        data: formData,
      );
      final responseData = jsonDecode(response.data);
      if (responseData['status'] == 1) {
        AppSP.set(AppSPKey.currentDevice, jsonEncode(device.toJson()));
      }
      return responseData['status'] == 1;
    } catch (_) {}

    return false;
  }
}
