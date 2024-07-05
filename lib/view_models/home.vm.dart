import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

import '../app/app_sp.dart';
import '../app/app_sp_key.dart';
import '../app/app_string.dart';
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
import '../view/video_camp/view_camp.dart';
import '../view/video_camp/view_camp_usb.dart';
import '../widget/pop_up.dart';

class HomeViewModel extends BaseViewModel {
  HomeViewModel({required this.context});

  final BuildContext context;

  final MethodChannel methodChannel =
      const MethodChannel('com.example.usb/serial');

  final CampRequest _campRequest = CampRequest();
  final DeviceRequest _deviceRequest = DeviceRequest();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  TextEditingController proUNController = TextEditingController();
  TextEditingController proPWController = TextEditingController();
  TextEditingController proIPController = TextEditingController();

  final focusNodeProUN = FocusNode();
  final focusNodeProPW = FocusNode();
  final focusNodeProIP = FocusNode();
  final focusNodeOpenPJ = FocusNode();
  final focusNodeClosePJ = FocusNode();
  final focusNodeOpenOnStart = FocusNode();
  final focusNodeUSB = FocusNode();
  final focusNodeCamp = FocusNode();

  ValueChanged<String>? callbackCommand;

  List<CampModel> camps = [];
  List<CampSchedule> lstCampSchedule = [];
  List<PacketModel> packets = [];

  User currentUser = User();
  DeviceInfoModel? deviceInfo;

  bool isDrawerOpen = false;
  bool playVideo = true;
  bool turnOnlPJ = false;
  bool turnOffPJ = false;
  bool openOnStartup = false;
  bool? pauseVideo;

  Future<void> initialise() async {
    methodChannel.setMethodCallHandler(_handleMethodCall);

    String? info = AppSP.get(AppSPKey.user_info);
    if (info != null) {
      currentUser = User.fromJson(jsonDecode(AppSP.get(AppSPKey.user_info)));
      await AppUtils.platformChannel.invokeMethod(
          'saveUser', {AppSPKey.user_info: currentUser.customerId});
    }
    proUNController.text = AppSP.get(AppSPKey.proUN) ?? '';
    proPWController.text = AppSP.get(AppSPKey.proPW) ?? '';
    proIPController.text = AppSP.get(AppSPKey.projectorIP) ?? '';

    await fetchDeviceInfo();
    await getMyCamp();
    await getCampSchedule();

    notifyListeners();
  }

  @override
  void dispose() {
    proUNController.dispose();
    proPWController.dispose();
    proIPController.dispose();

    focusNodeProUN.dispose();
    focusNodeProPW.dispose();
    focusNodeProIP.dispose();
    focusNodeOpenPJ.dispose();
    focusNodeClosePJ.dispose();
    focusNodeOpenOnStart.dispose();
    focusNodeUSB.dispose();
    focusNodeCamp.dispose();

    camps.clear();
    lstCampSchedule.clear();
    packets.clear();

    callbackCommand = null;

    super.dispose();
  }

  void setCallback(ValueChanged<String>? callback) {
    callbackCommand = callback;
    pauseVideo = null;
  }

  Future<String?> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case AppString.stopVideo:
        callbackCommand?.call(AppString.stopVideo);
        return callbackCommand == null
            ? AppString.notPlayVideo
            : AppString.successCommand;

      case AppString.pauseVideo:
        callbackCommand?.call(AppString.pauseVideo);
        return pauseVideo == null
            ? AppString.notPlayVideo
            : pauseVideo == true
                ? AppString.pauseVideoReturn
                : AppString.continueVideo;

      case AppString.restartVideo:
        if (callbackCommand != null) {
          callbackCommand?.call(AppString.stopVideo);
        }

        await getCampSchedule();
        playCamp(true);

        return AppString.successCommand;

      case AppString.playFromUSB:
        AppSP.set(AppSPKey.typePlayVideo, 'USB');

        if (callbackCommand != null) {
          callbackCommand!.call(AppString.stopVideo);
        }

        Future.delayed(const Duration(seconds: 1), () {
          playCamp(true);
        });

        return AppString.successCommand;

      case AppString.playFromCamp:
        AppSP.set(AppSPKey.typePlayVideo, 'Chiendich');

        if (callbackCommand != null) {
          callbackCommand!.call(AppString.stopVideo);
        }

        Future.delayed(const Duration(seconds: 1), () async {
          await getCampSchedule();
          playCamp(true);
        });

        return AppString.successCommand;
    }

    return null;
  }

  void toggleDrawer() {
    isDrawerOpen = !isDrawerOpen;
    notifyListeners();
  }

  Future<void> nexPlayVideoUSB() async {
    List<String> usbPaths = await UsbService().getUsbPath();
    if (usbPaths.isEmpty && context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          Future.delayed(const Duration(seconds: 3), () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          });

          return PopUpWidget(
            icon: Image.asset("assets/images/ic_error.png"),
            title: 'Không có usb kết nối',
            leftText: 'Xác nhận',
            onLeftTap: () {
              Navigator.of(context).pop();
            },
          );
        },
      );
      playVideo = false;
    } else if (context.mounted) {
      Navigator.push(
        context,
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
      context: context,
      builder: (context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });

        return PopUpWidget(
          icon: Image.asset("assets/images/ic_error.png"),
          title: 'Gói cước hết hạn',
          leftText: 'Xác nhận',
          onLeftTap: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> signOut() async {
    AppSP.set(AppSPKey.token, '');
    AppSP.set(AppSPKey.user_info, '');
    AppSP.set(AppSPKey.lstCampSchedule, '');

    await AppUtils.platformChannel.invokeMethod('clearUser');

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const SplashPage(),
          ),
          (router) => false);
    }
  }

  Future<void> getMyCamp() async {
    camps = await _campRequest.getAllCampByIdCustomer();
    notifyListeners();
  }

  Future<void> getCampSchedule() async {
    lstCampSchedule = await _campRequest.getCampSchedule();

    List<Map<String, dynamic>> jsonList =
        lstCampSchedule.map((camp) => camp.toJson()).toList();
    String lstCampScheduleString = jsonEncode(jsonList);
    AppSP.set(AppSPKey.lstCampSchedule, lstCampScheduleString);
  }

  Future<void> fetchDeviceInfo() async {
    deviceInfo = await _deviceInfoService.getDeviceInfo();
    notifyListeners();
  }

  Future<void> connectDevice() async {
    bool checkConnect =
        await _deviceRequest.connectDevice(deviceInfo!, currentUser);
    if (context.mounted) {
      if (checkConnect) {
        Navigator.pop(context);
        AppSP.set(AppSPKey.proPW, proPWController.text);
        AppSP.set(AppSPKey.proUN, proUNController.text);
        AppSP.set(AppSPKey.projectorIP, proIPController.text);
        showDialog(
          context: context,
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
          context: context,
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

  void turnOnl() {
    turnOnlPJ = !turnOnlPJ;
    AppSP.set(AppSPKey.turnOnlPJ, turnOnlPJ.toString());
    notifyListeners();
  }

  void turnOff() {
    turnOffPJ = !turnOffPJ;
    AppSP.set(AppSPKey.turnOfflPJ, turnOffPJ.toString());
    notifyListeners();
  }

  void openOnStart() {
    openOnStartup = !openOnStartup;
    AppSP.set(AppSPKey.openPJOnStartup, openOnStartup.toString());
    notifyListeners();
  }

  Future<void> playCamp(bool check) async {
    playVideo = check;
    if (playVideo == true) {
      if (AppSP.get(AppSPKey.typePlayVideo) == 'Chiendich') {
        await _fetchPackets();
        if (AppString.checkPacket && context.mounted) {
          Navigator.push(
              context,
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
