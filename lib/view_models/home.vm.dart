import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:play_box/app/app_string.dart';
import 'package:play_box/view/video_camp/view_camp.dart';
import 'package:stacked/stacked.dart';

import '../app/app_sp.dart';
import '../app/app_sp_key.dart';
import '../app/app_utils.dart';
import '../models/camp/camp_model.dart';
import '../models/camp/camp_schedule.dart';
import '../models/device/device_info_model.dart';
import '../models/packet/packet_model.dart';
import '../models/user/user.dart';
import '../request/camp/camp.request.dart';
import '../request/device/device.request.dart';
import '../request/packet/packet.request.dart';
import '../services/device.service.dart';
import '../services/usb.service.dart';
import '../view/splash/splash.page.dart';
import '../view/video_camp/view_camp_usb.dart';
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
  DeviceInfoService deviceInfoService = DeviceInfoService();
  Dio dio = Dio();
  List<PacketModel> packets = [];
  bool isDrawerOpen = false;
  bool playVideo = true;

  initialise() async {
    String? info = AppSP.get(AppSPKey.user_info);
    if (info != null) {
      currentUser = User.fromJson(jsonDecode(AppSP.get(AppSPKey.user_info)));
    }
    proUN.text = AppSP.get(AppSPKey.proUN) ?? '';
    proPW.text = AppSP.get(AppSPKey.proPW) ?? '';
    projectorIP.text = AppSP.get(AppSPKey.projectorIP) ?? '';
    // bool checkPlayVideo =
    //     bool.parse(AppSP.get(AppSPKey.checkPlayVideo) ?? 'false');

    print('Giá trị: ${proUN.text}');

    await fetchDeviceInfo();
    await getMyCamp();
    await getCampSchedule();
    // AppSP.set(AppSPKey.checkPlayVideo, "true");
    List<CampSchedule> lstCampSchedule = await CampRequest().getCampSchedule();
    List<Map<String, dynamic>> jsonList =
        lstCampSchedule.map((camp) => camp.toJson()).toList();
    String lstCampScheduleString = jsonEncode(jsonList);
    AppSP.set(AppSPKey.lstCampSchedule, lstCampScheduleString);
    notifyListeners();
  }

  void setMethodCall(Future<dynamic> Function(MethodCall)? methodCall) {
    AppUtils.platformChannel.setMethodCallHandler(methodCall ?? _handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    print('Home call - ${call.method}');
    switch (call.method) {
      case 'yourFlutterMethod':
        String param = call.arguments['yourParameter'];
        // Thực hiện lệnh Flutter của bạn ở đây
        print("Received parameter from Kotlin: $param");
    // Trả về kết quả (nếu cần)
      default:
        throw MissingPluginException('Not implemented: ${call.method}');
    }
  }

  void toggleDrawer() {
    isDrawerOpen = !isDrawerOpen;
    notifyListeners();
  }

  void setContext(BuildContext ctx) {
    viewContext = ctx;
  }

  nexPlayVideoUSB() async {
    List<String> usbPaths = await UsbService().getUsbPath();
    if (usbPaths.isEmpty) {
      showDialog(
          context: viewContext,
          builder: (context) => PopUpWidget(
                icon: Image.asset("assets/images/ic_error.png"),
                title: 'Không có usb kết nối',
                leftText: 'Xác nhận',
                onLeftTap: () {
                  Navigator.pop(context);
                },
              ));
      playVideo = false;
    } else {
      Navigator.push(viewContext,
          MaterialPageRoute(builder: (viewContext) => VideoUSBPage()));
    }
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

    await AppUtils.platformChannel.invokeMethod('clearUser');

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

  playCamp(bool check) async {
    print('Check play camp1');
    playVideo = check;
    if (playVideo == true) {
      print('Check play camp');
      if (AppSP.get(AppSPKey.typePlayVideo) == 'Chiendich') {
        await _fetchPackets();
        if (AppString.checkPacket) {
          Navigator.push(
              viewContext,
              MaterialPageRoute(
                  builder: (context) => ViewCamp(
                        homeViewModel: this,
                      )));
        }
      } else {
        nexPlayVideoUSB();
      }
    }
    notifyListeners();
  }
}
