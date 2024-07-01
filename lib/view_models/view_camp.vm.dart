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
  static const usbEventChannel = EventChannel('com.example.usb/event');
  List<String> usbPaths = [];
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
  String checkUSB = '';
  String errorString = '';
  String checkConnectUSB = '';
  StreamSubscription? _usbSubscription;
  bool checkAlive = true;
  void init(List<CampSchedule> campSchedules) {
    _loadNextMedia(campSchedules);
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      print('Số giây');
      _updateTime();
    });
    _usbSubscription =
        usbEventChannel.receiveBroadcastStream().listen(_onUsbEvent);
  }

  void _onUsbEvent(dynamic event) {
    if (event == 'USB_DISCONNECTED') {
      print('USB bị rút');
      checkConnectUSB = 'USB bị rút';
      _controller?.pause();
      _controller = null;
      _getUsbPath(); // Cập nhật lại danh sách USB path
      notifyListeners();
    } else if (event == 'USB_CONNECTED') {
      print('USB được kết nối');
      checkConnectUSB = 'USB được kết nối';
      _getUsbPath(); // Cập nhật lại danh sách USB path
    }
  }

  void disposeViewModel() {
    print('Dispose play camp');
    checkAlive = false;
    _controller?.dispose();
    _timer?.cancel();
    checkAlive = false;
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
    try {
      var result = await platform.invokeMethod('getUsbPath');
      for (var path in result) {
        usbPath.add(path.toString());
      }
    } on PlatformException catch (e) {
      print('Lỗi: $e');
      errorString = e.toString();
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

  Future<void> _loadNextMedia(List<CampSchedule> campSchedules) async {
    if (!checkAlive) {
      return;
    }
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
          if (usbPaths.isNotEmpty) {
            checkUSB = 'Có usb: ${usbPaths.first}';
          } else {
            checkUSB = 'Không có usb';
          }

          if ((campSchedule.videoType == 'url' &&
                  _isImage(campSchedule.urlYoutube)) ||
              (campSchedule.videoType == 'usb' &&
                  _isImage(campSchedule.urlUsb))) {
            checkVideo = 'Chạy hình';
            checkImage = true;
            if (usbPaths.isNotEmpty) {
              String nameImageSave = campSchedule.urlYoutube.split('/').last;
              String savePath = '${usbPaths.first}/Images/$nameImageSave';
              Directory imageDir = Directory('${usbPaths.first}/Images');
              if (!imageDir.existsSync()) {
                imageDir.createSync(recursive: true);
              }
              if (campSchedule.videoType == 'url') {
                if (!File(savePath).existsSync()) {
                  VideoDownloader.startDownload(
                      campSchedule.urlYoutube, savePath, (progress) {});
                  checkPlay = 'Chạy url';
                }
                if (File(savePath).existsSync()) {
                  image = File(savePath);
                  checkPlay = 'Chạy usb';
                }
              } else if (File('${usbPaths.first}/Images/${campSchedule.urlUsb}')
                  .existsSync()) {
                checkPlay = 'Chạy usb';
                image = File('${usbPaths.first}/Images/${campSchedule.urlUsb}');
              } else {
                _loadNextMediaAfterDelay(campSchedules, false);
                return;
              }
            }
            notifyListeners();
            Future.delayed(_waitTime, () async {
              _onMediaFinished(campSchedules);
            });
          } else {
            checkImage = false;
            checkVideo = 'Chạy video';

            if (usbPaths.isEmpty) {
              _controller?.dispose();
              _controller = VideoPlayerController.networkUrl(
                  Uri.parse(campSchedule.urlYoutube));
            } else {
              String nameVideoSave = campSchedule.urlYoutube.split('/').last;
              String savePath = '${usbPaths.first}/Video/$nameVideoSave';
              Directory videoDir = Directory('${usbPaths.first}/Video');

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
                  checkPlay = 'Chạy url';
                } else {
                  _controller?.dispose();
                  _controller = VideoPlayerController.file(File(savePath));
                  checkPlay = 'Chạy usb';
                }
              } else {
                String usbPathh =
                    '${usbPaths.first}/Video/${campSchedule.urlUsb}';
                if (File(usbPathh).existsSync()) {
                  _controller?.dispose();
                  _controller = VideoPlayerController.file(File(usbPathh));
                  checkPlay = 'Chạy usb';
                } else {
                  _loadNextMediaAfterDelay(campSchedules, false);
                  return;
                }
              }
            }
            _initializeVideoPlayerFuture = _controller!.initialize();
            await _initializeVideoPlayerFuture;
            _controller!.setLooping(true);
            _controller!.play();
            notifyListeners();
            Future.delayed(_waitTime, () async {
              _onMediaFinished(campSchedules);
            });
          }
        } catch (e) {
          print('Error loading media: $e');
          _loadNextMediaAfterDelay(campSchedules);
        }
      } else {
        _loadNextMediaAfterDelay(campSchedules, false);
      }
    }
  }

  Future<void> _loadNextMediaAfterDelay(List<CampSchedule> campSchedules,
      [bool delay = true]) async {
    _currentIndex++;
    print('object: $_currentIndex');
    if (_currentIndex >= campSchedules.length) {
      _currentIndex = 0; // Lặp lại từ video đầu tiên
    }
    if (delay) {
      Future.delayed(_waitTime, () {
        _loadNextMedia(campSchedules);
      });
    } else {
      _loadNextMedia(campSchedules);
    }
  }

  void _onMediaFinished(List<CampSchedule> campSchedules) {
    print('onFinish');
    CampRequest campRequest = CampRequest();
    campRequest.addCampaignRunProfile(campSchedule);
    NotifyRequest notifyRequest = NotifyRequest();
    Notify notify = Notify(
      title: 'Chạy chiến dịch',
      descript: 'Chạy chiến dịch ${campSchedule.campaignName}',
      detail: 'Chạy chiến dịch ${campSchedule.campaignName}',
      picture: '',
    );
    notifyRequest.addNotify(notify);
    _currentIndex++;
    if (_currentIndex >= campSchedules.length) {
      _currentIndex = 0; // Lặp lại từ video đầu tiên
    }
    _loadNextMedia(campSchedules);
  }
}
