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
    Device device =
        Device.fromJson(jsonDecode(AppSP.get(AppSPKey.currentDevice)));
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
      getCampSchedule1();
    }
    if (device.turnoffTime != null && device.turnonTime != null) {
      DateTime turnOff = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(device.turnoffTime!.split(':')[0].toString().trim()),
          int.parse(device.turnoffTime!.split(':')[1].toString().trim()));
      DateTime turnOnl = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(device.turnonTime!.split(':')[0].toString().trim()),
          int.parse(device.turnonTime!.split(':')[1].toString().trim()));
      if (now.hour == turnOff.hour && now.minute == turnOff.minute) {
        Duration difference = turnOnl.difference(turnOff);
        print("Đúng điều kiện ngủ");
        _scheduleSleep(difference);
      }
    }
    // if(device.turnOff)
  }

  void _scheduleSleep(Duration delay) async {
    bool isDeviceOwner = await DevicePolicyController.instance.isAdminActive();

    if (isDeviceOwner) {
      print("Cho thiết bị ngủ");
      _navigationService.clearStackAndShow(Routes.homePage);
      bool success = await DevicePolicyController.instance.lockDevice();
      if (success) {
        // ScaffoldMessenger.of(viewContext).showSnackBar(
        //   const SnackBar(content: Text('Thiết bị đã được khóa.')),
        // );
        print('Thiết bị đã được khóa.');
        await _alarmService.setWakeUpAlarm(delay.inSeconds);
        homeViewModel.playCamp(true);
      } else {
        ScaffoldMessenger.of(viewContext).showSnackBar(
          const SnackBar(content: Text('Không thể khóa thiết bị.')),
        );
        print('Không thể khóa thiết bị.');
      }

      // ScaffoldMessenger.of(viewContext).showSnackBar(
      //   SnackBar(
      //       content: Text(
      //           'Đã đặt lịch khóa thiết bị sau ${delay.inMinutes} phút và đánh thức sau cùng.')),
      // );
    } else {
      ScaffoldMessenger.of(viewContext).showSnackBar(
        const SnackBar(content: Text('Ứng dụng không phải là Device Owner.')),
      );
    }
  }

  Future<void> getCampSchedule1() async {
    lstCampSchedule = await _campRequest.getCampSchedule();
    List<Map<String, dynamic>> jsonList =
        lstCampSchedule.map((camp) => camp.toJson()).toList();
    String lstCampScheduleString = jsonEncode(jsonList);
    AppSP.set(AppSPKey.lstCampSchedule, lstCampScheduleString);
  }

  DateTime stringToDateTime(String time) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final second = int.parse(parts[2]);
    return DateTime(now.year, now.month, now.day, hour, minute, second)
        .toUtc()
        .add(const Duration(hours: 7));
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
  }
}
