import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:play_box/app/app_sp.dart';
import 'package:play_box/app/app_sp_key.dart';
import 'package:play_box/app/app_string.dart';
import 'package:play_box/models/camp/camp_schedule.dart';
import 'package:play_box/request/camp/camp.request.dart';
import 'package:stacked/stacked.dart';

import '../view/video_camp/view_camp.dart';
import 'home.vm.dart';

class TimerClockViewModel extends BaseViewModel {
  late BuildContext viewContext;
  late Timer _timer;
  late DateTime _currentTime;
  Dio dio = Dio();
  bool flagPlayCamp = false;
  bool isPlaying = false;
  String proUN = '';
  String proPW = '';
  String projectorIP = '';
  bool? checkPacket;
  String day = '';
  HomeViewModel? homeViewModel;

  String get currentTimeFormatted => _formatTime(_currentTime);

  void initialize() {
    _currentTime = DateTime.now().toUtc().add(const Duration(hours: 7));
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _updateTime();
    });
  }

  Future<void> _updateTime() async {
    _currentTime = DateTime.now().toUtc().add(const Duration(hours: 7));
    notifyListeners();
    day = AppSP.get(AppSPKey.day) ?? '';
    proUN = AppSP.get(AppSPKey.proUN) ?? '';
    proPW = AppSP.get(AppSPKey.proPW) ?? '';
    String offProjector =
        'http://$proUN:$proPW@$projectorIP/cgi-bin/sd95.cgi?cm=0200a13d0203';
    String onProjector =
        "http://$proUN:$proPW@$projectorIP/cgi-bin/sd95.cgi?cm=0200a13d0103";
    projectorIP = AppSP.get(AppSPKey.projectorIP) ?? '';
    if (day !=
        DateTime.now()
            .toUtc()
            .add(const Duration(hours: 7))
            .toString()
            .substring(0, 10)) {
      print('Đúng điều kiện để lấy lịch chiếu');
      AppSP.set(
          AppSPKey.day,
          DateTime.now()
              .toUtc()
              .add(const Duration(hours: 7))
              .toString()
              .substring(0, 10));
      List<CampSchedule> lstCampSchedule =
          await CampRequest().getCampSchedule();
      List<Map<String, dynamic>> jsonList =
          lstCampSchedule.map((camp) => camp.toJson()).toList();
      String lstCampScheduleString = jsonEncode(jsonList);
      AppSP.set(AppSPKey.lstCampSchedule, lstCampScheduleString);
    }
    String? lstCampScheduleString = AppSP.get(AppSPKey.lstCampSchedule);
    checkPacket = AppString.checkPacket;
    if (lstCampScheduleString != null &&
        lstCampScheduleString != '' &&
        checkPacket != null) {
      List<dynamic> lstCampScheduleJson = jsonDecode(lstCampScheduleString);
      // print('Camp đã lưu: $lstCampScheduleString');
      DateTime now = DateTime.now().toUtc().add(const Duration(hours: 7));

      List<CampSchedule> lstCampScheduleNew = lstCampScheduleJson
          .map((e) => CampSchedule.fromJson(e))
          .where((camp) {
        DateTime fromTime = stringToDateTime(camp.fromTime);
        DateTime toTime = stringToDateTime(camp.toTime);
        return fromTime.isBefore(now) &&
            toTime.isAfter(now) &&
            camp.status == '1' &&
            checkPacket!;
      }).toList();
      print('Số lượng lịch chạy: ${lstCampScheduleNew.length}');
      if (AppSP.get(AppSPKey.checkPlayVideo) == 'true') {
        print('Đúng điều kiện checkplay video');
        if (lstCampScheduleNew.isEmpty) {
          if (isPlaying) {
            if (AppSP.get(AppSPKey.turnOfflPJ) == 'true') {
              print('Tắt máy chiếu');
              dio.get(offProjector);
            }
            print('Vào tắt video');
            Navigator.pop(viewContext);
            isPlaying = false;
            flagPlayCamp = false;
            notifyListeners();
          }
        } else {
          print('Vào play video');
          if (AppSP.get(AppSPKey.turnOnlPJ) == 'true') {
            print('Mở máy chiếu');
            dio.get(onProjector);
          }
          if (!flagPlayCamp) {
            isPlaying = true;
            notifyListeners();
            Navigator.push(
              viewContext,
              MaterialPageRoute(
                builder: (context) => ViewCamp(
                  campSchedules: lstCampScheduleNew,
                ),
              ),
            ).then((_) {
              flagPlayCamp = false;
              isPlaying = false;
              homeViewModel!.notifyListeners();
              if (AppSP.get(AppSPKey.turnOfflPJ) == 'true') {
                print('Tắt máy chiếu');
                dio.get(offProjector);
              }
              notifyListeners();
            });
            flagPlayCamp = true;
          }
        }
      }
    }
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

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
