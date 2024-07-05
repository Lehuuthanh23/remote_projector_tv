import 'dart:async';
import 'dart:convert';

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

  final MethodChannel methodChannel =
      const MethodChannel('com.example.usb/serial');
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

  final focusNodeProUN = FocusNode();
  final focusNodeProPW = FocusNode();
  final focusProjectorIP = FocusNode();
  final focusOpenPJ = FocusNode();
  final focusClosePJ = FocusNode();
  final focusOpenOnStart = FocusNode();
  final focusUSB = FocusNode();
  final focusCamp = FocusNode();

  ValueChanged<String>? callbackCommand;

  initialise() async {
    methodChannel.setMethodCallHandler(_handleMethodCall);

    String? info = AppSP.get(AppSPKey.user_info);
    if (info != null) {
      currentUser = User.fromJson(jsonDecode(AppSP.get(AppSPKey.user_info)));
      await AppUtils.platformChannel.invokeMethod(
          'saveUser', {AppSPKey.user_info: currentUser.customerId});
    }
    proUN.text = AppSP.get(AppSPKey.proUN) ?? '';
    proPW.text = AppSP.get(AppSPKey.proPW) ?? '';
    projectorIP.text = AppSP.get(AppSPKey.projectorIP) ?? '';

    print('Giá trị: ${proUN.text}');

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

  void setCallback(ValueChanged<String>? callback) {
    callbackCommand = callback;
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case AppString.stopVideo:
        callbackCommand?.call(AppString.stopVideo);
        break;
      case AppString.pauseVideo:
        callbackCommand?.call(AppString.pauseVideo);
        break;
      case AppString.restartVideo:

        break;
      case AppString.playFromUSB:

        break;
      case AppString.playFromCamp:

        break;
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
    if (usbPaths.isEmpty && viewContext.mounted) {
      showDialog(
          context: viewContext,
          builder: (context) => PopUpWidget(
                icon: Image.asset("assets/images/ic_error.png"),
                title: 'Không có usb kết nối',
                leftText: 'Xác nhận',
                onLeftTap: () {
                  Navigator.pop(context);
                },
              ),
      );
      playVideo = false;
    } else if (viewContext.mounted) {
      Navigator.push(
        viewContext,
        MaterialPageRoute(
            builder: (viewContext) => VideoUSBPage(homeViewModel: this)),
      );
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
            ),
    );
  }

  signOut() async {
    AppSP.set(AppSPKey.token, '');
    AppSP.set(AppSPKey.user_info, '');
    AppSP.set(AppSPKey.lstCampSchedule, '');

    await AppUtils.platformChannel.invokeMethod('clearUser');

    if (viewContext.mounted) {
      Navigator.pushAndRemoveUntil(
          viewContext,
          MaterialPageRoute(
            builder: (context) => const SplashPage(),
          ), (router) => false);
    }
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
    if (viewContext.mounted) {
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
        if (AppString.checkPacket && viewContext.mounted) {
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
