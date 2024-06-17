import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:play_box/models/device/device_info_model.dart';
import 'package:play_box/models/device/device_model.dart';
import '../../app/app_sp.dart';
import '../../app/app_sp_key.dart';
import '../../app/app_utils.dart';
import '../../constants/api.dart';
import '../../models/camp/camp_model.dart';
import '../../models/camp/camp_schedule.dart';
import '../../models/camp/time_run_model.dart';
import '../../models/user/user.dart';
import '../device/device.request.dart';

class CampRequest {
  final Dio dio = Dio();

  Future<List<CampModel>> getAllCampByIdCustomer() async {
    List<CampModel> lstCamp = [];
    User currentUser = User.fromJson(jsonDecode(AppSP.get(AppSPKey.user_info)));
    DeviceInfoModel deviceInfoModel =
        DeviceInfoModel.fromJson(jsonDecode(AppSP.get(AppSPKey.device)));
    DeviceRequest deviceRequest = DeviceRequest();
    List<Device> lstDevice =
        await deviceRequest.getDeviceByCustomerId(currentUser.customerId!);
    Device device = lstDevice
        .where((device) => device.serialComputer == deviceInfoModel.androidId)
        .toList()
        .first;
    AppSP.set(AppSPKey.computer, jsonEncode(device.toJson()));
    final response = await dio.get(
      '${Api.hostApi}${Api.getCampBySeriComputer}/${deviceInfoModel.androidId}',
    );
    final responseData = jsonDecode(response.data);
    print(responseData);
    List<dynamic> campList = responseData['Camp_list'];

    if (campList.isNotEmpty) {
      lstCamp = campList.map((e) => CampModel.fromJson(e)).toList();
    }

    // Get TimeRunModel for each CampModel
    for (var camp in lstCamp) {
      camp.lstTimeRun = await getTimeRunCampById(camp.campaignId);
    }
    return lstCamp;
  }

  Future<List<TimeRunModel>> getTimeRunCampById(String campaignId) async {
    List<TimeRunModel> listTime = [];
    final response = await dio.get(
      '${Api.hostApi}${Api.getTimeRunByCampId}/$campaignId',
    );
    final responseData = jsonDecode(response.data);
    List<dynamic> timeList = responseData['camp_list_time'];
    if (timeList.isNotEmpty) {
      listTime = timeList.map((e) => TimeRunModel.fromJson(e)).toList();
    }

    return listTime;
  }

  Future<List<CampSchedule>> getCampSchedule() async {
    List<CampSchedule> lstCampSchedule = [];
    Device device = Device.fromJson(jsonDecode(AppSP.get(AppSPKey.computer)));
    User currentUser = User.fromJson(jsonDecode(AppSP.get(AppSPKey.user_info)));
    final formData = FormData.fromMap({
      'computer_id': device.computerId,
      'customer_id': currentUser.customerId,
      'work_date': DateTime.now().toIso8601String().split('T').first,
    });
    final response = await dio.post(
      '${Api.hostApi}${Api.getAllRunTimeOfComputer}',
      options: AppUtils.createOptionsNoCookie(),
      data: formData,
    );
    //print('Body: $response');
    final responseData = jsonDecode(response.data);
    List<dynamic> timeCampSchedule = responseData['Camp_list'];
    lstCampSchedule =
        timeCampSchedule.map((e) => CampSchedule.fromJson(e)).toList();
    return lstCampSchedule;
  }
}
