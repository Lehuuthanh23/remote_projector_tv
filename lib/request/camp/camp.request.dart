import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../app/app_sp.dart';
import '../../app/app_sp_key.dart';
import '../../app/app_utils.dart';
import '../../constants/api.dart';
import '../../models/camp/camp_model.dart';
import '../../models/camp/camp_schedule.dart';
import '../../models/camp/time_run_model.dart';
import '../../models/device/device_info_model.dart';
import '../../models/device/device_model.dart';
import '../../models/user/user.dart';
import '../device/device.request.dart';

class CampRequest {
  final Dio _dio = Dio();

  final DeviceRequest _deviceRequest = DeviceRequest();

  Future<List<CampModel>> getAllCampByIdCustomer() async {
    List<CampModel> lstCamp = [];
    User currentUser = User.fromJson(jsonDecode(AppSP.get(AppSPKey.userInfo)));
    String? deviceString = AppSP.get(AppSPKey.device);

    if (deviceString.isEmptyOrNull) return [];

    DeviceInfoModel deviceInfoModel =
        DeviceInfoModel.fromJson(jsonDecode(deviceString!));
    List<Device> lstDevice =
        (await _deviceRequest.getDeviceByCustomerId(currentUser.customerId!)).where((device) =>
        device.serialComputer ==
            (deviceInfoModel.serialNumber == 'unknown'
                ? deviceInfoModel.androidId
                : deviceInfoModel.serialNumber))
            .toList();
    Device? device = lstDevice.isNotEmpty ? lstDevice.first : null;
    AppSP.set(AppSPKey.computer, device!= null ? jsonEncode(device.toJson()) : '');

    if (device != null) {
      await AppUtils.platformChannel.invokeMethod('saveComputer', {
        AppSPKey.serialComputer: device.serialComputer,
        AppSPKey.computerId: device.computerId
      });

      try {
        final response = await _dio.get(
          '${Api.hostApi}${Api.getCampByDevice}/${device.computerId}',
        );
        final responseData = jsonDecode(response.data);
        List<dynamic> campList = responseData['Camp_list'];

        if (campList.isNotEmpty) {
          lstCamp = campList.map((e) => CampModel.fromJson(e)).toList();
        }

        // Get TimeRunModel for each CampModel
        for (var camp in lstCamp) {
          camp.lstTimeRun = await getTimeRunCampById(camp.campaignId);
        }
      } catch (_) {}
    }

    return lstCamp;
  }

  Future<List<TimeRunModel>> getTimeRunCampById(String campaignId) async {
    List<TimeRunModel> listTime = [];

    try {
      final response = await _dio.get(
        '${Api.hostApi}${Api.getTimeRunByCampId}/$campaignId',
      );

      final responseData = jsonDecode(response.data);
      List<dynamic> timeList = responseData['camp_list_time'];

      if (timeList.isNotEmpty) {
        listTime = timeList.map((e) => TimeRunModel.fromJson(e)).toList();
      }
    } catch (_) {}

    return listTime;
  }

  Future<List<CampSchedule>> getCampSchedule() async {
    List<CampSchedule> lstCampSchedule = [];
    String? deviceString = AppSP.get(AppSPKey.computer);

    if (deviceString.isEmptyOrNull) return [];

    Device device = Device.fromJson(jsonDecode(deviceString!));
    final formData = FormData.fromMap({
      'computer_id': device.computerId,
      'work_date': DateTime.now().toIso8601String().split('T').first,
    });

    try {
      final response = await _dio.post(
        '${Api.hostApi}${Api.getAllRunTimeOfComputer}',
        options: AppUtils.createOptionsNoCookie(),
        data: formData,
      );

      final responseData = jsonDecode(response.data);
      List<dynamic> timeCampSchedule = responseData['Camp_list'];

      lstCampSchedule =
          timeCampSchedule.map((e) => CampSchedule.fromJson(e)).toList();
    } catch (_) {}

    return lstCampSchedule;
  }

  Future<void> addCampaignRunProfile(CampSchedule camp) async {
    User currentUser = User.fromJson(jsonDecode(AppSP.get(AppSPKey.userInfo)));
    Device device = Device.fromJson(jsonDecode(AppSP.get(AppSPKey.computer)));

    final formData = FormData.fromMap({
      'customer_id': currentUser.customerId,
      'customer_name': currentUser.customerName,
      'campaign_id': camp.campaignId,
      'campaign_name': camp.campaignName,
      'url': camp.videoType == 'url' ? camp.urlYoutube : camp.urlUsb,
      'computer_id': device.customerId,
      'seri_computer': device.serialComputer,
      'run_time': DateTime.now().toUtc().add(const Duration(hours: 7)),
      'computer_name': device.computerName,
    });

    try {
      await _dio.post(
        AppUtils.createUrl(Api.addCampaignRunProfile),
        options: AppUtils.createOptionsNoCookie(),
        data: formData,
      );
    } catch(_) {}
  }
}
