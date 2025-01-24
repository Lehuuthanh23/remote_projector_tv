import 'dart:async';
import 'dart:convert';
import 'package:device_policy_controller/device_policy_controller.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../app/app.locator.dart';
import '../app/app.router.dart';
import '../app/app_sp.dart';
import '../app/app_sp_key.dart';
import '../models/camp/camp_schedule.dart';
import '../models/device/device_model.dart';
import '../request/camp/camp.request.dart';
import '../services/alarm_service.dart';
import 'home.vm.dart';

class TimerClockViewModel extends BaseViewModel {
  TimerClockViewModel({required this.viewContext, required this.homeViewModel});

  final BuildContext viewContext;
  final HomeViewModel homeViewModel;

  late Timer _timer;
  final AlarmService _alarmService = AlarmService();
  final CampRequest _campRequest = CampRequest();
  static final _navigationService = appLocator<NavigationService>();
  DateTime _currentTime = DateTime.now().toUtc().add(const Duration(hours: 7));
  String get currentTimeFormatted => _formatTime(_currentTime);
  List<CampSchedule> lstCampSchedule = [];
  String proUN = '';
  String proPW = '';
  String projectorIP = '';
  bool? checkPacket;
  String day = '';
  int routerStackLength = 0;
  bool flagPlayCamp = false;
  bool isPlaying = false;
  bool isScheduled = false;

  Future<void> initialize() async {
    _currentTime = DateTime.now().toUtc().add(const Duration(hours: 7));
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _updateTime();
    });
    List<CampSchedule> lstCampSchedule = await _campRequest.getCampSchedule();
    List<Map<String, dynamic>> jsonList =
        lstCampSchedule.map((camp) => camp.toJson()).toList();
    String lstCampScheduleString = jsonEncode(jsonList);
    AppSP.set(AppSPKey.lstCampSchedule, lstCampScheduleString);
  }

  @override
  void dispose() {
    _timer.cancel();

    super.dispose();
  }

  Future<void> _updateTime() async {
    _currentTime = DateTime.now().toUtc().add(const Duration(hours: 7));
    homeViewModel.currentTimeFormatted = currentTimeFormatted;
    Device? device;
    if (AppSP.get(AppSPKey.currentDevice) != 'null' &&
        AppSP.get(AppSPKey.currentDevice) != null) {
      device = Device.fromJson(jsonDecode(AppSP.get(AppSPKey.currentDevice)));
    }
    notifyListeners();
    day = AppSP.get(AppSPKey.day) ?? '';
    proUN = AppSP.get(AppSPKey.proUN) ?? '';
    proPW = AppSP.get(AppSPKey.proPW) ?? '';
    // String offProjector =
    //     'http://$proUN:$proPW@$projectorIP/cgi-bin/sd95.cgi?cm=0200a13d0203';
    // String onProjector =
    //     "http://$proUN:$proPW@$projectorIP/cgi-bin/sd95.cgi?cm=0200a13d0103";
    projectorIP = AppSP.get(AppSPKey.projectorIP) ?? '';
    DateTime now = DateTime.now().toUtc().add(const Duration(hours: 7));
    if (day != now.toString().substring(0, 10)) {
      AppSP.set(AppSPKey.day, now.toString().substring(0, 10));
      await homeViewModel.viewCampViewModel.syncVideo();
      await getCampSchedule1();
    }
    if (device != null &&
        device.turnoffTime != null &&
        device.turnonTime != null &&
        device.turnoffTime!.trim().isNotEmpty &&
        device.turnonTime!.trim().isNotEmpty) {
      // Phân tách giờ và phút từ chuỗi thời gian
      List<String> turnOffParts =
          device.turnoffTime!.split(':').map((s) => s.trim()).toList();
      List<String> turnOnParts =
          device.turnonTime!.split(':').map((s) => s.trim()).toList();

      // Tạo DateTime cho turnOff
      DateTime turnOff = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(turnOffParts[0]),
        int.parse(turnOffParts[1]),
      );

      // Tạo DateTime cho turnOn
      DateTime turnOn = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(turnOnParts[0]),
        int.parse(turnOnParts[1]),
      );

      // Nếu turnOn nhỏ hơn hoặc bằng turnOff, thêm một ngày vào turnOn
      if (turnOn.isBefore(turnOff) || turnOn.isAtSameMomentAs(turnOff)) {
        turnOn = turnOn.add(const Duration(days: 1));
      }

      // Kiểm tra xem hiện tại có trùng với thời gian turnOff không
      if (now.hour == turnOff.hour && now.minute == turnOff.minute) {
        Duration difference = turnOn.difference(turnOff);
        print("Đúng điều kiện ngủ");
        if (!isScheduled) {
          _scheduleSleep(difference);
        }
      }
      if (now.isAfter(turnOn)) {
        isScheduled = false;
      }
    }
    // if(device.turnOff)
  }

  void _scheduleSleep(Duration delay) async {
    print('Vào _scheduleSleep');

    bool isDeviceOwner = await DevicePolicyController.instance.isAdminActive();
    isScheduled = true;
    if (isDeviceOwner) {
      print("Cho thiết bị ngủ");
      await homeViewModel.viewCampViewModel.syncVideo();
      homeViewModel.setCallback(null);
      bool success = await DevicePolicyController.instance.lockDevice();

      if (success) {
        print('Thiết bị đã được khóa.');
        if (homeViewModel.playVideo && viewContext.mounted) {
          Navigator.pop(viewContext);
        }
        await homeViewModel.playCamp(false);
        print('ngủ trong: ${delay.inSeconds}');
        await _alarmService.setWakeUpAlarm(delay.inSeconds);
        print('Đã đặt thời gian thức dậy');
        _alarmService.listenForWakeUpEvents(() async {
          // Khi thiết bị thức dậy
          print('Thiết bị đã thức dậy.');

          // Tiến hành các hành động khi thiết bị thức dậy
          homeViewModel.playCamp(true); // Đánh thức và tiếp tục
          print('Đã hết thời gian, thiết bị sẽ thức dậy.');

          // Hiển thị SnackBar
          ScaffoldMessenger.of(viewContext).showSnackBar(
            const SnackBar(
                content: Text('Đã hết thời gian, thiết bị sẽ thức dậy.')),
          );
        });
        // await Future.delayed(delay, () {
        //   homeViewModel.playCamp(true); // Đánh thức và tiếp tục
        //   print('Đã hết thời gian, thiết bị sẽ thức dậy.');
        //   ScaffoldMessenger.of(viewContext).showSnackBar(
        //     const SnackBar(
        //         content: Text('Đã hết thời gian, thiết bị sẽ thức dậy.')),
        //   );
        // });
      } else {
        // ScaffoldMessenger.of(viewContext).showSnackBar(
        //   const SnackBar(content: Text('Không thể khóa thiết bị.')),
        // );
        print('Không thể khóa thiết bị.');
      }
    } else {
      // ScaffoldMessenger.of(viewContext).showSnackBar(
      //   const SnackBar(content: Text('Ứng dụng không phải là Device Owner.')),
      // );
    }
  }

  Future<void> getCampSchedule1() async {
    lstCampSchedule = await _campRequest.getCampSchedule();
    List<Map<String, dynamic>> jsonList =
        lstCampSchedule.map((camp) => camp.toJson()).toList();
    String lstCampScheduleString = jsonEncode(jsonList);
    AppSP.set(AppSPKey.lstCampSchedule, lstCampScheduleString);
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
  }
}
