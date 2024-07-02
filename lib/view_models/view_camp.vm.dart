import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:video_player/video_player.dart';

import '../../models/camp/camp_schedule.dart';
import '../../models/notification/notify_model.dart';
import '../../request/camp/camp.request.dart';
import '../../request/notification/notify.request.dart';
import '../view/video_camp/video_downloader.dart';

class ViewCampViewModel extends BaseViewModel {
  static const platform = MethodChannel('com.example.usb/serial');
  static const usbEventChannel = EventChannel('com.example.usb/event');

  VideoPlayerController? _controller;
  VideoPlayerController? get controller => _controller;
  String _formattedTime = '';
  String get formattedTime => _formattedTime;

  final List<CampSchedule> campSchedulesNew;
  final BuildContext context;

  ViewCampViewModel({required this.campSchedulesNew, required this.context});

  List<String> usbPaths = [];
  int currentIndex = 0;
  int _waitTime = 0;
  File? image;
  bool checkImage = false;
  bool checkAlive = true;
  bool? checkDisconnectUSB;
  late Timer _timerTimeShowing;

  void init() {
    _loadNextMedia(campSchedulesNew);
    _updateTime();
    _timerTimeShowing = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      _updateTime();
    });
    usbEventChannel.receiveBroadcastStream().listen(_onUsbEvent);
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

  @override
  void dispose() {
    checkAlive = false;
    _controller?.dispose();
    _timerTimeShowing.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final formattedTime = DateFormat('HH:mm:ss').format(now);
    _formattedTime = formattedTime;
    notifyListeners();
  }

  Future<void> _getUsbPath() async {
    List<String> usbPath = [];
    var result = await platform.invokeMethod('getUsbPath');
    for (var path in result) {
      usbPath.add(path.toString());
    }
    usbPaths = usbPath;
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

  Future<void> _loadNextMedia(List<CampSchedule> campSchedules, {int timeStart = 0}) async {
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
              String nameImageSave = currentCampSchedule.urlYoutube.split('/').last;
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
              } else if (File('${usbPaths.first}/Images/${currentCampSchedule.urlUsb}')
                  .existsSync()) {
                image = File('${usbPaths.first}/Images/${currentCampSchedule.urlUsb}');
              } else {
                _loadNextMediaInList(campSchedules);
                return;
              }
            }
            notifyListeners();
            var counter = _waitTime - timeStart;
            Timer.periodic(const Duration(seconds: 1), (timer) {
              counter--;
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
          } else {
            checkImage = false;

            if (usbPaths.isEmpty) {
              _controller = VideoPlayerController.networkUrl(
                  Uri.parse(currentCampSchedule.urlYoutube));
            } else {
              String nameVideoSave = currentCampSchedule.urlYoutube.split('/').last;
              String savePath = '${usbPaths.first}/Video/$nameVideoSave';
              Directory videoDir = Directory('${usbPaths.first}/Video');

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
                    '${usbPaths.first}/Video/${currentCampSchedule.urlUsb}';
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
              counter--;
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
