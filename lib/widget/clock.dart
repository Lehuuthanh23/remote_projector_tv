import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:play_box/app/app_sp.dart';
import 'package:play_box/app/app_sp_key.dart';
import 'package:play_box/view/video_camp/view_camp.page.dart';

import '../models/camp/camp_schedule.dart';
import '../request/camp/camp.request.dart';

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
  bool flagPlayVideo = false;
  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now().toUtc().add(const Duration(hours: 7));
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _updateTime();
    });
  }

  Future<void> _updateTime() async {
    // AppSP.set(AppSPKey.day, '');
    // AppSP.set(AppSPKey.lstCampSchedule, '');

    setState(() {
      _currentTime = DateTime.now().toUtc().add(const Duration(hours: 7));
    });
    //AppSP.set(AppSPKey.day, '');
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
      print('Camp đã lưu: $lstCampScheduleString');
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
      if (lstCampScheduleNew.isNotEmpty && flagPlayVideo == false) {
        print('Mở xem video');
        dio.get(
            'http://admin1:panasonic@192.168.1.100/cgi-bin/sd95.cgi?cm=0200a13d0103');
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewCampPage(
                lstCampSchedule: lstCampScheduleNew,
              ),
            ));
        flagPlayVideo = true;
      } else if (lstCampScheduleNew.isEmpty) {
        dio.get(
            'http://admin1:panasonic@192.168.1.100/cgi-bin/sd95.cgi?cm=0200a13d0203');
      }
    }
  }

  DateTime stringToDateTime(String time) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final second = int.parse(parts[2]);
    return DateTime(now.year, now.month, now.day, hour, minute, second).toUtc();
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
