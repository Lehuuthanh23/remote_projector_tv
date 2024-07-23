import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
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
import '../request/command/command.request.dart';
import '../request/device/device.request.dart';
import '../request/packet/packet.request.dart';
import '../services/device.service.dart';
import '../services/google_sigin_api.service.dart';
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
  final CommandRequest _commandRequest = CommandRequest();

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
  String? currentTimeFormatted;

  bool isDrawerOpen = false;
  bool playVideo = true;
  bool turnOnlPJ = false;
  bool turnOffPJ = false;
  bool openOnStartup = false;
  bool? pauseVideo;

  Future<void> initialise() async {
    String? info = AppSP.get(AppSPKey.userInfo);
    if (info != null) {
      currentUser = User.fromJson(jsonDecode(AppSP.get(AppSPKey.userInfo)));
      await AppUtils.platformChannel.invokeMethod(
          'saveUser', {AppSPKey.userInfo: currentUser.customerId});
    }
    proUNController.text = AppSP.get(AppSPKey.proUN) ?? '';
    proPWController.text = AppSP.get(AppSPKey.proPW) ?? '';
    proIPController.text = AppSP.get(AppSPKey.projectorIP) ?? '';

    await fetchDeviceInfo();
    await _getTokenAndSendToServer();
    await getValue();
    _setupTokenRefreshListener();
    _setupForegroundMessageListener();
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

  Future<void> _getTokenAndSendToServer() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();
      if (token != null) {
        _deviceRequest.updateDeviceFirebaseToken(token);
      }
    } catch (_) {}
  }

  void _setupTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _deviceRequest.updateDeviceFirebaseToken(newToken);
    });
  }

  void _setupForegroundMessageListener() {
    FirebaseMessaging.onMessage.listen(_onMessageReceive);
  }

  Future<void> _onMessageReceive(RemoteMessage message) async {
    String? commandId = message.data['cmd_id'];
    String? command = message.data['cmd_code'];

    if (command != null && commandId != null) {
      String? replyContent = await onCommandChecked(command);
      if (replyContent != null) {
        await _commandRequest.replyCommand(commandId, replyContent);
      }
    }
  }

  Future<String?> onCommandChecked(String? command) async {
    switch (command) {
      case AppString.getTimeNow:
        return currentTimeFormatted;

      case AppString.restartApp:
        AppUtils.channelRestart.invokeMethod('restartApp');
        return AppString.successCommand;

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

      case AppString.deleteDevice:
        if (callbackCommand != null) {
          callbackCommand!.call(AppString.stopVideo);
        }

        AppSP.set(AppSPKey.computer, '');
        AppSP.set(AppSPKey.lstCampSchedule, '[]');

        getValue();
        return null;

      default:
        return null;
    }
  }

  Future<void> getValue() async {
    await getMyCamp();
    await getCampSchedule();

    notifyListeners();
  }

  void setCallback(ValueChanged<String>? callback) {
    callbackCommand = callback;
    pauseVideo = null;
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
          title: 'Không có gói cước hiệu lực',
          leftText: 'Xác nhận',
          onLeftTap: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> signOut() async {
    await _deviceRequest.updateDeviceFirebaseToken('');
    print('Đang nhập bằng: (${AppSP.get(AppSPKey.loginWith)})');
    if (AppSP.get(AppSPKey.loginWith) == 'google') {
      await GoogleSignInService.logout();
    }
    AppSP.set(AppSPKey.token, '');
    AppSP.set(AppSPKey.userInfo, '');
    AppSP.set(AppSPKey.lstCampSchedule, '[]');

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
        _getTokenAndSendToServer();
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
    AppSP.set(AppSPKey.turnOffPJ, turnOffPJ.toString());
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
