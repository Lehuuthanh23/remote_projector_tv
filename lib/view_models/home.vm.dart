import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

import '../app/app_sp.dart';
import '../app/app_sp_key.dart';
import '../models/camp/camp_model.dart';
import '../models/camp/camp_schedule.dart';
import '../models/device/device_info_model.dart';
import '../models/user/user.dart';
import '../request/camp/camp.request.dart';
import '../request/device/device.request.dart';
import '../services/device_service.dart';
import '../view/splash/splash.page.dart';
import '../widget/pop_up.dart';

class HomeViewModel extends BaseViewModel {
  late BuildContext viewContext;
  CampRequest campRequest = CampRequest();
  bool turnOnlPJ = false;
  bool turnOffPJ = false;
  bool openOnStartup = false;
  List<CampModel> camps = [];
  List<CampSchedule> lstCampSchedule = [];
  User currentUser = User();
  DeviceInfoModel? deviceInfo;
  DeviceRequest deviceRequest = DeviceRequest();
  TextEditingController proUN = TextEditingController();
  TextEditingController proPW = TextEditingController();
  TextEditingController projectorIP = TextEditingController();
  initialise() async {
    currentUser = User.fromJson(jsonDecode(AppSP.get(AppSPKey.user_info)));
    await fetchDeviceInfo();
    await getMyCamp();
    await getCampSchedule();
    List<CampSchedule> lstCampSchedule = await CampRequest().getCampSchedule();
    List<Map<String, dynamic>> jsonList =
        lstCampSchedule.map((camp) => camp.toJson()).toList();
    String lstCampScheduleString = jsonEncode(jsonList);
    AppSP.set(AppSPKey.lstCampSchedule, lstCampScheduleString);
    print('Số lượng camp schedule: ${lstCampSchedule.length}');
    print('User hiện tại là: ${currentUser.customerName}');
    notifyListeners();
  }

  void setContext(BuildContext ctx) {
    viewContext = ctx;
  }

  signOut() async {
    AppSP.set(AppSPKey.token, '');
    AppSP.set(AppSPKey.user_info, '');
    AppSP.set(AppSPKey.lstCampSchedule, '');
    const platform = MethodChannel('com.example/my_channel');
    platform.invokeMethod('clearUser');
    Navigator.pushAndRemoveUntil(
        viewContext,
        MaterialPageRoute(
          builder: (context) => const SplashPage(),
        ),
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
    bool checkConnect =
        await deviceRequest.connectDevice(deviceInfo!, currentUser);
    if (checkConnect) {
      showDialog(
        context: viewContext,
        builder: (BuildContext context) {
          return PopUpWidget(
            icon: Image.asset("assets/images/ic_success.png"),
            title: 'Kết nối thành công',
            leftText: 'Xác nhận',
            onLeftTap: () {
              Navigator.pop(context);
            },
          );
        },
      );
    } else {
      showDialog(
        context: viewContext,
        builder: (BuildContext context) {
          return PopUpWidget(
            icon: Image.asset("assets/images/ic_error.png"),
            title: 'Kết nối thất bại',
            leftText: 'Xác nhận',
            onLeftTap: () {
              Navigator.pop(context);
            },
          );
        },
      );
    }
  }

  turnOnl() {
    turnOnlPJ = !turnOnlPJ;
    AppSP.set(AppSPKey.turnOnlPJ, turnOnlPJ.toString());
    notifyListeners();
  }

  turnOff() {
    turnOffPJ = !turnOffPJ;
    AppSP.set(AppSPKey.turnOfflPJ, turnOffPJ.toString());
    notifyListeners();
  }

  openOnStart() {
    openOnStartup = !openOnStartup;
    AppSP.set(AppSPKey.turnOfflPJ, openOnStartup.toString());
    notifyListeners();
  }
}
