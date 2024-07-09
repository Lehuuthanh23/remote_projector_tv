import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:video_player/video_player.dart';

import '../app/app_sp.dart';
import '../app/app_sp_key.dart';
import '../app/app_string.dart';
import '../models/camp/camp_schedule.dart';
import '../models/notification/notify_model.dart';
import '../observer/navigator_observer.dart';
import '../request/camp/camp.request.dart';
import '../request/notification/notify.request.dart';
import '../services/usb.service.dart';
import '../view/video_camp/video_downloader.dart';
import 'home.vm.dart';

class ViewCampViewModel extends BaseViewModel {
  ViewCampViewModel({
    required this.context,
    required this.homeViewModel,
  });

  final BuildContext context;
  final HomeViewModel homeViewModel;

  static const usbEventChannel = EventChannel('com.example.usb/event');
  final Dio _dio = Dio();

  VideoPlayerController? _controller;
  VideoPlayerController? get controller => _controller;

  String _formattedTime = '';
  String get formattedTime => _formattedTime;

  late Timer _timerTimeShowing;

  List<String> usbPaths = [];
  List<CampSchedule> campSchedulesNew = [];

  File? image;
  String proUN = '';
  String proPW = '';
  String projectorIP = '';
  String offProjector = '';
  String onProjector = '';
  int currentIndex = 0;
  int _waitTime = 0;
  int routerStackLength = 0;

  bool? checkDisconnectUSB;
  bool? checkPacket;
  bool isPlaying = true;
  bool flagPlayCamp = false;
  bool pauseVideo = false;
  bool checkImage = false;
  bool checkAlive = true;

  void init() {
    checkAlive = true;
    proUN = AppSP.get(AppSPKey.proUN) ?? '';
    proPW = AppSP.get(AppSPKey.proPW) ?? '';
    projectorIP = AppSP.get(AppSPKey.projectorIP) ?? '';
    offProjector =
        'http://$proUN:$proPW@$projectorIP/cgi-bin/sd95.cgi?cm=0200a13d0203';
    onProjector =
        "http://$proUN:$proPW@$projectorIP/cgi-bin/sd95.cgi?cm=0200a13d0103";

    _timerTimeShowing = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      checkNumberOfPages(context);
      getCampSchedule();

      String? lstCampScheduleString = AppSP.get(AppSPKey.lstCampSchedule);
      List<dynamic> lstCampScheduleJson = jsonDecode(lstCampScheduleString!);
      DateTime now = DateTime.now().toUtc().add(const Duration(hours: 7));

      if (lstCampScheduleJson
          .map((e) => CampSchedule.fromJson(e))
          .where((camp) {
            DateTime fromTime = stringToDateTime(camp.fromTime);
            DateTime toTime = stringToDateTime(camp.toTime);
            return fromTime.isBefore(now) &&
                toTime.isAfter(now) &&
                camp.status == '1' &&
                AppString.checkPacket;
          })
          .toList()
          .isEmpty) {
        if (isPlaying) {
          isPlaying = false;
          flagPlayCamp = false;
          _controller?.pause();
          _controller = null;
          notifyListeners();
        }
      } else {
        if (AppSP.get(AppSPKey.turnOnlPJ) == 'true') {
          _dio.get(onProjector);
        }

        if (!flagPlayCamp) {
          isPlaying = true;
          notifyListeners();
          _loadNextMedia(campSchedulesNew);
          flagPlayCamp = true;
          notifyListeners();
        }
      }
      _updateTime();
    });

    usbEventChannel.receiveBroadcastStream().listen(_onUsbEvent);
    homeViewModel.setCallback(onCommandInvoke);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timerTimeShowing.cancel();

    checkAlive = false;
    usbPaths.clear();
    campSchedulesNew.clear();

    homeViewModel.setCallback(null);

    super.dispose();
  }

  void onCommandInvoke(String command) {
    if (command == AppString.pauseVideo) {
      pauseVideo = !pauseVideo;
      homeViewModel.pauseVideo = pauseVideo;

      if (pauseVideo) {
        _controller?.pause();
      } else {
        _controller?.play();
      }
    } else if (command == AppString.stopVideo) {
      popPage();
      homeViewModel.playVideo = false;
      Navigator.pop(context);
    }
  }

  void popPage() {
    checkAlive = false;
    homeViewModel.notifyListeners();
    if (AppSP.get(AppSPKey.turnOffPJ) == 'true') {
      _dio.get(offProjector);
    }
  }

  void getCampSchedule() {
    String? lstCampScheduleString = AppSP.get(AppSPKey.lstCampSchedule);
    checkPacket = AppString.checkPacket;

    if (lstCampScheduleString != null &&
        lstCampScheduleString != '' &&
        checkPacket != null) {
      List<dynamic> lstCampScheduleJson = jsonDecode(lstCampScheduleString);
      campSchedulesNew =
          lstCampScheduleJson.map((e) => CampSchedule.fromJson(e)).toList();
      notifyListeners();
    }
  }

  void checkNumberOfPages(BuildContext context) {
    final observer = Navigator.of(context).widget.observers.firstWhere(
          (o) => o is CustomNavigatorObserver,
        ) as CustomNavigatorObserver;

    routerStackLength = observer.routeStack.length;
  }

  Future<void> _onUsbEvent(dynamic event) async {
    if (event == 'USB_DISCONNECTED') {
      _controller?.dispose();
      checkDisconnectUSB = true;
    } else if (event == 'USB_CONNECTED') {
      checkDisconnectUSB = false;
      await _getUsbPath();
    }
  }

  void _updateTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final formattedTime = DateFormat('HH:mm:ss').format(now);
    _formattedTime = formattedTime;
    notifyListeners();
  }

  Future<void> _getUsbPath() async {
    usbPaths = await UsbService().getUsbPath();
    notifyListeners();
  }

  bool _isImage(String path) {
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif');
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

  Future<void> _loadNextMedia(List<CampSchedule> campSchedules,
      {int timeStart = 0}) async {
    if (!checkAlive || !context.mounted) return;
    _controller?.dispose();

    image = null;
    if (currentIndex < campSchedules.length) {
      CampSchedule currentCampSchedule = campSchedules[currentIndex];
      DateTime fromTime = stringToDateTime(currentCampSchedule.fromTime);
      DateTime toTime = stringToDateTime(currentCampSchedule.toTime);
      DateTime now = DateTime.now().toUtc().add(const Duration(hours: 7));

      if (fromTime.isBefore(now) &&
          toTime.isAfter(now) &&
          currentCampSchedule.status == '1') {
        _waitTime = int.parse(currentCampSchedule.videoDuration);
        try {
          await _getUsbPath();

          if (checkShowingImage(currentCampSchedule)) {
            checkImage = true;

            if (usbPaths.isNotEmpty) {
              String nameImageSave =
                  currentCampSchedule.urlYoutube.split('/').last;
              String savePath = '${usbPaths.first}/Images/$nameImageSave';
              Directory imageDir = Directory('${usbPaths.first}/Images');

              if (!imageDir.existsSync()) {
                imageDir.createSync(recursive: true);
              }

              if (currentCampSchedule.videoType == 'url') {
                if (!File(savePath).existsSync()) {
                  VideoDownloader.startDownload(
                      currentCampSchedule.urlYoutube, savePath, (progress) {});
                } else {
                  image = File(savePath);
                }
              } else if (File(
                      '${usbPaths.first}/Images/${currentCampSchedule.urlUsb}')
                  .existsSync()) {
                image = File(
                    '${usbPaths.first}/Images/${currentCampSchedule.urlUsb}');
              } else {
                _loadNextMediaInList(campSchedules);
                return;
              }
            }
            notifyListeners();
            var counter = _waitTime;
            Timer.periodic(const Duration(seconds: 1), (timer) {
              counter -= pauseVideo ? 0 : 1;

              if (checkDisconnectUSB == true) {
                timer.cancel();
                checkDisconnectUSB = null;
                _loadNextMedia(campSchedules);
              } else if (counter <= 0 || !context.mounted) {
                timer.cancel();
                checkDisconnectUSB = null;
                _onMediaFinished(campSchedules);
              }
            });
          } else {
            checkImage = false;

            if (usbPaths.isEmpty) {
              _controller = VideoPlayerController.networkUrl(
                  Uri.parse(currentCampSchedule.urlYoutube));
            } else {
              String nameVideoSave =
                  currentCampSchedule.urlYoutube.split('/').last;
              String savePath = '${usbPaths.first}/Videos/$nameVideoSave';
              Directory videoDir = Directory('${usbPaths.first}/Videos');

              if (currentCampSchedule.videoType == 'url') {
                if (!videoDir.existsSync()) {
                  videoDir.createSync(recursive: true);
                }

                if (!File(savePath).existsSync()) {
                  VideoDownloader.startDownload(
                      currentCampSchedule.urlYoutube, savePath, (progress) {});
                }

                if (!File(savePath).existsSync()) {
                  _controller = VideoPlayerController.networkUrl(
                      Uri.parse(currentCampSchedule.urlYoutube));
                } else {
                  _controller = VideoPlayerController.file(File(savePath));
                }
              } else {
                String usbPathh =
                    '${usbPaths.first}/Videos/${currentCampSchedule.urlUsb}';

                if (File(usbPathh).existsSync()) {
                  _controller = VideoPlayerController.file(File(usbPathh));
                } else {
                  _loadNextMediaInList(campSchedules);
                  return;
                }
              }
            }
            await _controller!.initialize();
            _controller!.setLooping(true);
            _controller!.play();

            if (timeStart > 0) {
              _controller!.seekTo(Duration(seconds: timeStart));
            }

            notifyListeners();
            var counter = _waitTime - timeStart;
            Timer.periodic(const Duration(seconds: 1), (timer) {
              counter -= pauseVideo ? 0 : 1;

              if (checkDisconnectUSB == true) {
                timer.cancel();
                checkDisconnectUSB = null;
                _loadNextMedia(campSchedules, timeStart: _waitTime - counter);
              } else if (counter <= 0 || !context.mounted) {
                timer.cancel();
                checkDisconnectUSB = null;
                _onMediaFinished(campSchedules);
              }
            });
          }
        } catch (e) {
          _loadNextMediaInList(campSchedules);
        }
      } else {
        _loadNextMediaInList(campSchedules);
      }
    }
  }

  Future<void> _loadNextMediaInList(List<CampSchedule> campSchedules) async {
    currentIndex++;
    if (currentIndex >= campSchedules.length) {
      currentIndex = 0;
    }

    checkDisconnectUSB = null;
    _loadNextMedia(campSchedules);
  }

  void _onMediaFinished(List<CampSchedule> campSchedules) {
    CampSchedule currentCampSchedule = campSchedules[currentIndex];
    CampRequest campRequest = CampRequest();
    NotifyRequest notifyRequest = NotifyRequest();

    campRequest.addCampaignRunProfile(currentCampSchedule);

    Notify notify = Notify(
      title: 'Chạy chiến dịch',
      descript: 'Chạy chiến dịch ${currentCampSchedule.campaignName}',
      detail: 'Chạy chiến dịch ${currentCampSchedule.campaignName}',
      picture: '',
    );
    notifyRequest.addNotify(notify);

    _loadNextMediaInList(campSchedules);
  }

  bool checkShowingImage(CampSchedule currentCampSchedule) {
    return (currentCampSchedule.videoType == 'url' &&
            _isImage(currentCampSchedule.urlYoutube)) ||
        (currentCampSchedule.videoType == 'usb' &&
            _isImage(currentCampSchedule.urlUsb));
  }
}
