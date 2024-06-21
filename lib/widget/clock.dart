import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:play_box/app/app_sp.dart';
import 'package:play_box/app/app_sp_key.dart';
import 'package:play_box/view/video_camp/view_camp_usb.page.dart';
import 'package:play_box/view/video_camp/view_camp_webview.page.dart';

import '../models/camp/camp_schedule.dart';
import '../request/camp/camp.request.dart';
import '../view/video_camp/test_get_usb.dart';
import '../view/video_camp/view_camp.dart';

class TimerClock extends StatefulWidget {
  const TimerClock({super.key});

  @override
  _TimerClockState createState() => _TimerClockState();
}

class _TimerClockState extends State<TimerClock> {
  late Timer _timer;
  late DateTime _currentTime;
  String day = '';
  Dio dio = Dio();
  bool flagPlayCamp = false; // Biến cờ hiệu để kiểm tra việc điều hướng
  bool isPlaying =
      false; // Biến cờ hiệu để kiểm tra xem đang phát video hay không

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now().toUtc().add(const Duration(hours: 7));
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _updateTime();
    });
  }

  Future<void> _updateTime() async {
    setState(() {
      _currentTime = DateTime.now().toUtc().add(const Duration(hours: 7));
    });

    day = AppSP.get(AppSPKey.day) ?? '';
    if (day != DateTime.now().toString().substring(0, 10)) {
      print('Đúng điều kiện để lấy lịch chiếu');
      AppSP.set(AppSPKey.day, DateTime.now().toString().substring(0, 10));
      List<CampSchedule> lstCampSchedule =
          await CampRequest().getCampSchedule();
      List<Map<String, dynamic>> jsonList =
          lstCampSchedule.map((camp) => camp.toJson()).toList();
      String lstCampScheduleString = jsonEncode(jsonList);
      AppSP.set(AppSPKey.lstCampSchedule, lstCampScheduleString);
    }
    String? lstCampScheduleString = AppSP.get(AppSPKey.lstCampSchedule);
    if (lstCampScheduleString != null && lstCampScheduleString != '') {
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
            camp.status == '1';
      }).toList();

      if (lstCampScheduleNew.isEmpty) {
        if (isPlaying) {
          print('Vào tắt video');
          Navigator.pop(context);
          setState(() {
            isPlaying = false;
            flagPlayCamp = false;
          });
        }
      } else {
        print('Vào play video');
        if (!flagPlayCamp) {
          setState(() {
            isPlaying = true;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerFromCampSchedule(
                campSchedules: lstCampScheduleNew,
                lstCampScheduleString: lstCampScheduleString,
              ),
            ),
          ).then((_) {
            setState(() {
              flagPlayCamp = false;
              isPlaying = false;
            });
          });
          flagPlayCamp = true;
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

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _formatTime(_currentTime),
        style: const TextStyle(fontSize: 48),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
  }
}
