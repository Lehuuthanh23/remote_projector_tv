import 'dart:async';
import 'dart:io';
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
  VideoPlayerController? _controller;
  VideoPlayerController? get controller => _controller;
  late Future<void> _initializeVideoPlayerFuture;
  int _currentIndex = 0;
  static const platform = MethodChannel('com.example.usb/serial');
  List<String> _usbPath = [];
  List<String> get usbPath => _usbPath;
  String nameVideo = '';
  String _formattedTime = '';
  String get formattedTime => _formattedTime;
  late Duration _waitTime;
  Timer? _timer;
  String checkPlay = '';
  bool checkImage = false;
  late CampSchedule campSchedule;
  File? image;
  String checkVideo = '';

  void init(List<CampSchedule> campSchedules) {
    _loadNextMedia(campSchedules);
    _updateTime();
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) => _updateTime());
  }

  void disposeViewModel() {
    _controller?.dispose();
    _timer?.cancel();
  }

  void _updateTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final formattedTime = DateFormat('HH:mm:ss').format(now);
    _formattedTime = formattedTime;
    notifyListeners();
  }

  Future<void> _getUsbPath() async {
    List<String> usbPath = [];
    try {
      var result = await platform.invokeMethod('getUsbPath');
      for (var path in result) {
        usbPath.add(path.toString());
      }
    } on PlatformException catch (e) {
      print('Lỗi: $e');
    }
    _usbPath = usbPath;
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

  Future<void> _loadNextMedia(List<CampSchedule> campSchedules) async {
    if (_currentIndex < campSchedules.length) {
      campSchedule = campSchedules[_currentIndex];
      DateTime fromTime = stringToDateTime(campSchedule.fromTime);
      DateTime toTime = stringToDateTime(campSchedule.toTime);
      DateTime now = DateTime.now().toUtc().add(const Duration(hours: 7));
      if (fromTime.isBefore(now) &&
          toTime.isAfter(now) &&
          campSchedule.status == '1') {
        nameVideo = campSchedule.campaignName;
        _waitTime = Duration(seconds: int.parse(campSchedule.videoDuration));
        try {
          await _getUsbPath();
          if ((campSchedule.videoType == 'url' &&
                  _isImage(campSchedule.urlYoutube)) ||
              (campSchedule.videoType == 'usb' &&
                  _isImage(campSchedule.urlUsb))) {
            checkVideo = 'Chạy hình';
            print('Chạy hình');
            checkImage = true;
            if (_usbPath.isNotEmpty) {
              String nameImageSave = campSchedule.urlYoutube.split('/').last;
              String savePath = '${_usbPath.first}/Images/$nameImageSave';
              Directory imageDir = Directory('${_usbPath.first}/Images');
              if (!imageDir.existsSync()) {
                imageDir.createSync(recursive: true);
              }
              if (campSchedule.videoType == 'url') {
                if (!File(savePath).existsSync()) {
                  VideoDownloader.startDownload(
                      campSchedule.urlYoutube, savePath, (progress) {});
                  checkVideo = '$checkVideo : chạy bằng url';
                }
                if (File(savePath).existsSync()) {
                  image = File(savePath);
                  checkVideo = '$checkVideo : chạy bằng usb';
                }
              } else if (File('${_usbPath.first}/Images/${campSchedule.urlUsb}')
                  .existsSync()) {
                image = File('${_usbPath.first}/Images/${campSchedule.urlUsb}');
                checkVideo = '$checkVideo : chạy bằng usb';
              } else {
                _currentIndex++;
                if (_currentIndex >= campSchedules.length) {
                  _currentIndex = 0; // Lặp lại từ video đầu tiên
                }
                _loadNextMedia(campSchedules);
              }
            }
            notifyListeners();
            Future.delayed(_waitTime, () async {
              CampRequest campRequest = CampRequest();
              await campRequest.addCampaignRunProfile(campSchedule);
              NotifyRequest notifyRequest = NotifyRequest();
              Notify notify = Notify(
                  title: 'Chạy chiến dịch',
                  descript: 'Chạy chiến dịch ${campSchedule.campaignName}',
                  detail: 'Chạy chiến dịch ${campSchedule.campaignName}',
                  picture: '');
              await notifyRequest.addNotify(notify);
              _currentIndex++;
              if (_currentIndex >= campSchedules.length) {
                _currentIndex = 0; // Lặp lại từ video đầu tiên
              }
              _loadNextMedia(campSchedules);
            });
          } else {
            checkImage = false;
            checkVideo = 'Chạy video';
            print('Chạy video');
            if (_usbPath.isEmpty) {
              _controller?.dispose();
              _controller = VideoPlayerController.networkUrl(
                  Uri.parse(campSchedule.urlYoutube));
            } else {
              String nameVideoSave = campSchedule.urlYoutube.split('/').last;
              String savePath = '${_usbPath.first}/Video/$nameVideoSave';
              Directory videoDir = Directory('${_usbPath.first}/Video');

              if (campSchedule.videoType == 'url') {
                if (!videoDir.existsSync()) {
                  videoDir.createSync(recursive: true);
                }
                if (!File(savePath).existsSync()) {
                  VideoDownloader.startDownload(
                      campSchedule.urlYoutube, savePath, (progress) {});
                }
                if (!File(savePath).existsSync()) {
                  _controller?.dispose();
                  _controller = VideoPlayerController.networkUrl(
                      Uri.parse(campSchedule.urlYoutube));
                  checkVideo = '$checkVideo : chạy bằng url';
                } else {
                  _controller?.dispose();
                  _controller = VideoPlayerController.file(File(savePath));
                  checkPlay = 'Chạy bằng USB : $savePath';
                  checkVideo = '$checkVideo : chạy bằng usb';
                }
              } else {
                String usbPathh = '';
                if (File('${_usbPath.first}/${campSchedule.urlUsb}')
                    .existsSync()) {
                  usbPathh = '${_usbPath.first}/Video/${campSchedule.urlUsb}';
                  print('usb path: $usbPathh');
                  _controller?.dispose();
                  _controller = VideoPlayerController.file(File(usbPathh));
                  checkVideo = '$checkVideo : chạy bằng usb';
                } else {
                  _currentIndex++;
                  if (_currentIndex >= campSchedules.length) {
                    _currentIndex = 0; // Lặp lại từ video đầu tiên
                  }
                  _loadNextMedia(campSchedules);
                }
              }
            }
            _initializeVideoPlayerFuture = _controller!.initialize();
            await _initializeVideoPlayerFuture;
            _controller!.setLooping(true);
            _controller!.play();
            notifyListeners();
            Future.delayed(_waitTime, () async {
              CampRequest campRequest = CampRequest();
              await campRequest.addCampaignRunProfile(campSchedule);
              NotifyRequest notifyRequest = NotifyRequest();
              Notify notify = Notify(
                  title: 'Chạy chiến dịch',
                  descript: 'Chạy chiến dịch ${campSchedule.campaignName}',
                  detail: 'Chạy chiến dịch ${campSchedule.campaignName}',
                  picture: '');
              await notifyRequest.addNotify(notify);
              _currentIndex++;
              if (_currentIndex >= campSchedules.length) {
                _currentIndex = 0; // Lặp lại từ video đầu tiên
              }
              _loadNextMedia(campSchedules);
            });
          }
        } catch (e) {
          print('Error loading video: $e');
          _currentIndex++;
          if (_currentIndex >= campSchedules.length) {
            _currentIndex = 0; // Lặp lại từ video đầu tiên
          }
          _loadNextMedia(campSchedules);
        }
      } else {
        _currentIndex++;
        if (_currentIndex >= campSchedules.length) {
          _currentIndex = 0; // Lặp lại từ video đầu tiên
        }
        _loadNextMedia(campSchedules);
      }
    }
  }
}
