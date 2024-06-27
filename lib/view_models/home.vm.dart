import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:play_box/app/app_string.dart';
import 'package:stacked/stacked.dart';

import '../app/app_sp.dart';
import '../app/app_sp_key.dart';
import '../models/camp/camp_model.dart';
import '../models/camp/camp_schedule.dart';
import '../models/device/device_info_model.dart';
import '../models/packet/packet_model.dart';
import '../models/user/user.dart';
import '../request/camp/camp.request.dart';
import '../request/device/device.request.dart';
import '../request/packet/packet.request.dart';
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
  Dio dio = Dio();
  List<PacketModel> packets = [];
  bool isDrawerOpen = false;

  initialise() async {
    currentUser = User.fromJson(jsonDecode(AppSP.get(AppSPKey.user_info)));
    proUN.text = AppSP.get(AppSPKey.proUN) ?? '';
    proPW.text = AppSP.get(AppSPKey.proPW) ?? '';
    projectorIP.text = AppSP.get(AppSPKey.projectorIP) ?? '';
    print('Giá trị: ${proUN.text}');
    await _fetchPackets();
    await fetchDeviceInfo();
    await getMyCamp();
    await getCampSchedule();
    List<CampSchedule> lstCampSchedule = await CampRequest().getCampSchedule();
    List<Map<String, dynamic>> jsonList =
        lstCampSchedule.map((camp) => camp.toJson()).toList();
    String lstCampScheduleString = jsonEncode(jsonList);
    AppSP.set(AppSPKey.lstCampSchedule, lstCampScheduleString);
    notifyListeners();
  }

  void toggleDrawer() {
    isDrawerOpen = !isDrawerOpen;
    notifyListeners();
  }

  void setContext(BuildContext ctx) {
    viewContext = ctx;
  }

  Future<void> _fetchPackets() async {
    packets = await PacketRequest().getPacketByCustomerId();
    AppString.checkPacket = packets.isNotEmpty;
    if (!AppString.checkPacket) {
      _showExpiredDialog();
    }
  }

  void _showExpiredDialog() {
    showDialog(
        context: viewContext,
        builder: (context) => PopUpWidget(
              icon: Image.asset("assets/images/ic_error.png"),
              title: 'Gói cước hết hạn',
              leftText: 'Xác nhận',
              onLeftTap: () {
                Navigator.pop(context);
              },
            ));
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
      Navigator.pop(viewContext);
      AppSP.set(AppSPKey.proPW, proPW.text);
      AppSP.set(AppSPKey.proUN, proUN.text);
      AppSP.set(AppSPKey.projectorIP, projectorIP.text);
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
    print('Giá trị lưu mở pj: ${AppSP.get(AppSPKey.turnOnlPJ)}');
    notifyListeners();
  }

  turnOff() {
    turnOffPJ = !turnOffPJ;
    AppSP.set(AppSPKey.turnOfflPJ, turnOffPJ.toString());
    print('Giá trị lưu tắt pj: ${AppSP.get(AppSPKey.turnOfflPJ)}');
    notifyListeners();
  }

  openOnStart() {
    openOnStartup = !openOnStartup;
    AppSP.set(AppSPKey.openPJOnStartup, openOnStartup.toString());
    print('Giá trị mở khi khởi động: ${AppSP.get(AppSPKey.openPJOnStartup)}');
    notifyListeners();
  }

  playCamp(bool check) {
    AppSP.set(AppSPKey.checkPlayVideo, '$check');
    print('Check play video: ${AppSP.get(AppSPKey.checkPlayVideo)}');
    notifyListeners();
  }
}
