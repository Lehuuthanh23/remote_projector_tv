import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../app/app_sp.dart';
import '../app/app_sp_key.dart';
import '../models/camp/camp_model.dart';
import '../models/camp/camp_schedule.dart';
import '../models/device/device_info_model.dart';
import '../models/user/user.dart';
import '../request/camp/camp.request.dart';
import '../services/device_service.dart';
import '../view/splash/splash.page.dart';

class HomeViewModel extends BaseViewModel {
  late BuildContext viewContext;
  CampRequest campRequest = CampRequest();
  List<CampModel> camps = [
    // CampModel(
    //   campaignId: '1',
    //   campaignName: 'CAMP BDS ĐỒNG NAI',
    //   status: 'Đang chạy',
    //   videoId: '1',
    //   fromDate: '2021-10-01',
    //   toDate: '2021-10-10',
    //   fromTime: '08:30',
    //   toTime: '17:30',
    //   daysOfWeek: 'T2,T3,T4',
    //   videoType: 'Youtube',
    //   urlYoutube: '',
    //   urlUSP: '',
    //   computerId: '123',
    // ),
    // CampModel(
    //   campaignId: '1',
    //   campaignName: 'CAMP BDS BÌNH DƯƠNG',
    //   status: 'Đang chạy',
    //   videoId: '1',
    //   fromDate: '2021-10-01',
    //   toDate: '2021-10-10',
    //   fromTime: '08:30',
    //   toTime: '17:30',
    //   daysOfWeek: 'T2,T3,T4',
    //   videoType: 'Youtube',
    //   urlYoutube: '',
    //   urlUSP: '',
    //   computerId: '123',
    // ),
    // // Thêm các CampModel khác nếu cần
  ];
  List<CampSchedule> lstCampSchedule = [];
  User currentUser = User();
  DeviceInfoModel? deviceInfo;
  initialise() async {
    currentUser = User.fromJson(jsonDecode(AppSP.get(AppSPKey.user_info)));
    await fetchDeviceInfo();
    await getMyCamp();
    await getCampSchedule();
    print('Số lượng camp schedule: ${lstCampSchedule.length}');
    print('User hiện tại là: ${currentUser.customerName}');
    notifyListeners();
  }

  signOut() async {
    await AppSP.set(AppSPKey.token, '');
    await AppSP.set(AppSPKey.user_info, '');
    Navigator.pushAndRemoveUntil(
        viewContext,
        MaterialPageRoute(builder: (context) => const SplashPage()),
        (router) => false);
  }

  getMyCamp() async {
    camps = await campRequest.getAllCampByIdCustomer();
    notifyListeners();
  }

  getCampSchedule() async {
    lstCampSchedule = await campRequest.getCampSchedule();
  }

  Future<void> fetchDeviceInfo() async {
    DeviceInfoService deviceInfoService = DeviceInfoService();
    deviceInfo = await deviceInfoService.getDeviceInfo();
    notifyListeners();
  }

  Future<void> connectDevice() async {
    
  }
}
