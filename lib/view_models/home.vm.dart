import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_policy_controller/device_policy_controller.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app/app_sp.dart';
import '../app/app_sp_key.dart';
import '../app/app_string.dart';
import '../app/app_utils.dart';
import '../app/convert_md5.dart';
import '../constants/app_info.dart';
import '../models/camp/camp_model.dart';
import '../models/camp/camp_schedule.dart';
import '../models/config/config_model.dart';
import '../models/device/device_info_model.dart';
import '../models/device/device_model.dart';
import '../models/dir/dir_model.dart';
import '../models/packet/packet_model.dart';
import '../models/user/user.dart';
import '../plugin/install_plugin.dart';
import '../request/camp/camp.request.dart';
import '../request/command/command.request.dart';
import '../request/config/config.request.dart';
import '../request/device/device.request.dart';
import '../request/dir/dir.request.dart';
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

  final CampRequest _campRequest = CampRequest();
  final DeviceRequest _deviceRequest = DeviceRequest();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  final CommandRequest _commandRequest = CommandRequest();
  final DirRequest _dirRequest = DirRequest();

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
  bool checkConnectDevice = false;

  CancelToken? _cancelToken;

  bool _permissionGranted = false;
  bool get permissionGranted => _permissionGranted;

  bool _isUpdate = false;
  bool get isUpdate => _isUpdate;

  bool _updateAvailable = false;
  bool get updateAvailable => _updateAvailable;

  double _progress = 0;
  double get progress => _progress;

  String? _tempPath;
  String? get tempPath => _tempPath;

  bool _newVersion = false;
  bool get newVersion => _newVersion;

  final List<Dir> _listDir = [];
  List<Dir> get listDir => _listDir;

  final List<Dir> _listShareDir = [];
  List<Dir> get listShareDir => _listShareDir;

  final List<Dir> _listDirAll = [];
  List<Dir> get listDirAll => _listDirAll;

  ConfigModel? _configModel;
  ConfigModel? get configModel => _configModel;

  final ConfigRequest _configRequest = ConfigRequest();
  final dpc = DevicePolicyController.instance;

  Dir? selectedDir;
  FocusNode focusNodeSelectDir = FocusNode();
  bool isFocusedSelectDir = false;

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
    await _checkVersionApp();
    await fetchDeviceInfo();
    await _getTokenAndSendToServer();
    await getValue();
    await getDir();
    if (AppSP.get(AppSPKey.currentDir) != 0) {
      print('hahaha');
      print(AppSP.get(AppSPKey.currentDir));
      selectedDir = _listDirAll
          .where((dir) {
            print(dir.dirName.toString());
            print(dir.dirId.toString());
            return dir.dirId.toString() ==
                AppSP.get(AppSPKey.currentDir).toString();
          })
          .toList()
          .first;
    }
    await WakelockPlus.enable();
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

    GoogleSignInService.dispose();
    WakelockPlus.disable();

    super.dispose();
  }

  onChangeDir(Dir? dir) {
    selectedDir = dir;
    AppSP.set(AppSPKey.currentDir, selectedDir?.dirId ?? 0);
    notifyListeners();
  }

  Future<void> getDir() async {
    setBusy(true);

    _listDirAll.clear();

    await getMyDir();
    await getShareDir();

    _listDirAll.addAll([..._listDir, ..._listShareDir]);
    _listDirAll.add(Dir());
    setBusy(false);
  }

  Future<void> getMyDir() async {
    _listDir.clear();
    _listDir.addAll(await _dirRequest.getMyDir());
    for (var dir in _listDir) {
      dir.isOwner = true;
    }
  }

  updateDirByDevice() async {
    Device device =
        Device.fromJson(jsonDecode(AppSP.get(AppSPKey.currentDevice)));
    if (AppSP.get(AppSPKey.currentDir) != null &&
        AppSP.get(AppSPKey.currentDir) != 0) {
      await _deviceRequest.updateDirByDevice(
          device, int.parse(AppSP.get(AppSPKey.currentDir).toString()));
      notifyListeners();
      print('Get xong danh sách camp');
    }
    await getValue();
  }

  Future<void> getShareDir() async {
    _listShareDir.clear();
    _listShareDir.addAll(await _dirRequest.getShareDir());
  }

  Future<void> openSettings() async {
    try {
      await dpc.unlockApp();
      print('Unlock App');

      final success = await dpc.startApp();
      if (success) {
        print("Settings opened successfully");
        AppSP.set(AppSPKey.isSettingsOpened, true);
        // isSettingsOpened = true;
      } else {
        print("Failed to open Settings");
      }
    } catch (e) {
      print("Error opening Settings: $e");
    }
  }

  Future<void> _getTokenAndSendToServer() async {
    bool checkFirebase = false;
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();

      if (token != null) {
        checkFirebase = await _commandRequest.checkFirebase(token);

        if (checkFirebase) {
          _setupTokenRefreshListener();
          _setupForegroundMessageListener();
        }
        await AppSP.set(AppSPKey.useFirebase, checkFirebase);
        await AppUtils.platformChannel.invokeMethod('firebase', {
          AppSPKey.useFirebase: checkFirebase,
        });
      }

      await _deviceRequest
          .updateDeviceFirebaseToken(checkFirebase ? token! : '');
    } catch (_) {}

    if (!checkFirebase) {
      AppUtils.platformChannel.setMethodCallHandler((methodCall) async {
        return await onCommandChecked(methodCall.method);
      });
    }
  }

  void _setupTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      bool useFirebase = AppSP.get(AppSPKey.useFirebase) ?? false;
      if (useFirebase) {
        _deviceRequest.updateDeviceFirebaseToken(newToken);
      }
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
    _checkVersionApp();
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
    print('Pathhhhhhh: ');
    print(usbPaths);
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
      bool? emptyList = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (viewContext) => VideoUSBPage(homeViewModel: this),
        ),
      );
      if (emptyList == true) {
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
              title: 'Usb hiện không có video hoặc hình ảnh trong thư mục',
              leftText: 'Xác nhận',
              onLeftTap: () {
                Navigator.of(context).pop();
              },
            );
          },
        );
      }

      playVideo = false;
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
                checkConnectDevice = true;
                notifyListeners();
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
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewCamp(
                homeViewModel: this,
              ),
            ),
          );
          playVideo == false;
        }
      } else {
        await nexPlayVideoUSB();
      }
    }
    notifyListeners();
  }

  //Check update
  void cancelDownloadTaped() {
    if (_tempPath != null) {
      _installApp();
    } else if (_isUpdate) {
      _cancelToken?.cancel();
      _cancelToken = null;
      _isUpdate = false;
      _progress = 0;
      _updateAvailable = false;
      notifyListeners();
    } else {
      if (Platform.isAndroid) {
        updateAndroidApp(_configModel?.appTVBoxUpdateUrl);
      }
    }
  }

  Future<void> _checkVersionApp() async {
    ConfigModel? config = await _configRequest.getConfig();
    saveConfig(config);
    String configString = AppSP.get(AppSPKey.config) ?? '';

    if (configString.isNotBlank) {
      _configModel = ConfigModel.fromJson(jsonDecode(configString));
      await Future.delayed(const Duration(milliseconds: 500));

      if (Platform.isAndroid) {
        String buildDate = _configModel?.appTVBoxBuildDate ??
            AppInfo.userAndroidAppInfo.buildDate;

        if (AppInfo.userAndroidAppInfo.buildDate.isBeforeBuildDate(buildDate)) {
          _newVersion = true;
          notifyListeners();
          // showDialog(
          //   barrierDismissible: false,
          //   context: context,
          //   builder: (BuildContext context) {
          //     return PopUpWidget(
          //       icon: Image.asset("assets/images/ic_error.png"),
          //       title:
          //           'Để tiếp tục sử dụng ứng dụng, vui lòng cập nhật ứng dụng lên phiên bản mới nhất.\nPhiên bản: ${_configModel?.appUserAndroidVersion ?? ''}\nNgày phát hành: ${_configModel?.appUserAndroidBuildDate ?? ''}',
          //       leftText: 'Xác nhận',
          //       onLeftTap: () {
          //         Navigator.pop(context);
          //         _updateAndroidApp(_configModel?.appUserAndroidUpdateUrl);
          //       },
          //     );
          //   },
          // );
        }
      } else if (Platform.isIOS) {
        String buildDate =
            _configModel?.appTVBoxBuildDate ?? AppInfo.userIOSAppInfo.buildDate;

        if (AppInfo.userIOSAppInfo.buildDate.isBeforeBuildDate(buildDate)) {
          _newVersion = true;
          notifyListeners();
          // showDialog(
          //   context: context,
          //   barrierDismissible: false,
          //   builder: (BuildContext context) {
          //     return PopUpWidget(
          //       icon: Image.asset("assets/images/ic_error.png"),
          //       title:
          //           'Để tiếp tục sử dụng ứng dụng, vui lòng cập nhật ứng dụng lên phiên bản mới nhất.\nPhiên bản: ${_configModel?.appUserAndroidVersion ?? ''}\nNgày phát hành: ${_configModel?.appUserAndroidBuildDate ?? ''}',
          //       leftText: 'Xác nhận',
          //       onLeftTap: () {
          //         Navigator.pop(context);
          //         launchUrl(Uri.parse(_configModel?.appUserIosUpdateUrl ?? ''));
          //       },
          //     );
          //   },
          // );
        }
      }
    }
  }

  Future<void> updateAndroidApp(String? url) async {
    if (url == null || _isUpdate == true) return;

    if (!_permissionGranted) {
      _permissionGranted = await InstallPlugin.requestPermission() ?? false;
    }
    _updateAvailable = true;
    notifyListeners();

    if (_permissionGranted) {
      _isUpdate = true;
      _progress = 0;
      _permissionGranted = true;
      _cancelToken = CancelToken();

      notifyListeners();

      var appDocDir = await getTemporaryDirectory();
      String savePath = "${appDocDir.path}/${url.split('/').last}";

      var response = await Dio().download(
        url,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (count, total) {
          final value = count / total;
          if (_progress != value) {
            _progress = value;
            notifyListeners();
          }
        },
      );

      if (response.statusCode == 200) {
        _tempPath = savePath;

        _installApp();
      }
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PopUpWidget(
            icon: Image.asset("assets/images/ic_error.png"),
            title:
                'Để tiếp tục việc cập nhật ứng dụng, bạn cần cấp quyền cài đặt ứng dụng từ bên ngoài.\nMở cài đặt?',
            leftText: 'Xác nhận',
            onLeftTap: () async {
              _permissionGranted =
                  await InstallPlugin.requestPermission(openSetting: true) ??
                      false;
            },
          );
        },
      );
    }
  }

  Future<void> _installApp() async {
    if (_tempPath == null) return;

    final res = await InstallPlugin.install(_tempPath!);

    if (!res['isSuccess'] == true) {
      _isUpdate = false;
      _cancelToken = null;
      _progress = 0;
      notifyListeners();
    }
  }
}
