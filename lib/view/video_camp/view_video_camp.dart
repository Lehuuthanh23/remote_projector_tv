import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:play_box/app/app_sp.dart';
import 'package:play_box/app/app_sp_key.dart';
import 'package:video_player/video_player.dart';
import '../../models/camp/camp_schedule.dart';
import '../../models/notification/notify_model.dart';
import '../../request/camp/camp.request.dart';
import '../../request/notification/notify.request.dart';
import 'video_downloader.dart';

class ViewVideoCamp extends StatefulWidget {
  final List<CampSchedule> campSchedules;
  final String lstCampScheduleString;
  ViewVideoCamp(
      {Key? key,
      required this.campSchedules,
      required this.lstCampScheduleString})
      : super(key: key);

  @override
  _ViewVideoCampState createState() => _ViewVideoCampState();
}

class _ViewVideoCampState extends State<ViewVideoCamp> {
  VideoPlayerController? _controller;
  late Future<void> _initializeVideoPlayerFuture;
  int _currentIndex = 0;
  static const platform = MethodChannel('com.example.usb/serial');
  List<String> _usbPath = [];
  String nameVideo = '';
  String _formattedTime = '';
  late Duration _waitTime;
  Timer? _timer;
  String checkPlay = '';

  @override
  void initState() {
    super.initState();
    _loadNextVideo();
    _updateTime();

    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final formattedTime = DateFormat('HH:mm:ss').format(now);
    if (mounted) {
      setState(() {
        _formattedTime = formattedTime;
      });
    }
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

    if (mounted) {
      setState(() {
        _usbPath = usbPath;
      });
    }
  }

  Future<void> _loadNextVideo() async {
    if (_currentIndex < widget.campSchedules.length) {
      final campSchedule = widget.campSchedules[_currentIndex];
      nameVideo = campSchedule.campaignName;
      _waitTime = Duration(seconds: int.parse(campSchedule.videoDuration));
      try {
        await _getUsbPath();
        if (_usbPath.isEmpty) {
          _controller?.dispose();
          _controller = VideoPlayerController.networkUrl(
              Uri.parse(campSchedule.urlYoutube));
          checkPlay = 'Chạy bằng Url';
        } else {
          String nameVideoSave = campSchedule.urlYoutube
              .split('/')
              .last
              .split('.')
              .first
              .toString();
          String savePath = '${_usbPath.first}/Video/$nameVideoSave.mp4';
          Directory videoDir = Directory('${_usbPath.first}/Video');
          if (!videoDir.existsSync()) {
            videoDir.createSync(recursive: true);
          }
          if (!File(savePath).existsSync()) {
            VideoDownloader.startDownload(
                campSchedule.urlYoutube, savePath, (progress) {});
          } else {
            widget.campSchedules[_currentIndex].videoType = 'usb';
          }
          if (campSchedule.videoType == 'url') {
            _controller?.dispose();
            _controller = VideoPlayerController.networkUrl(
                Uri.parse(campSchedule.urlYoutube));
            checkPlay = 'Chạy bằng Url';
          } else {
            String usbPathh = '';
            if (File('${_usbPath.first}/Video/$nameVideoSave.mp4')
                .existsSync()) {
              usbPathh = '${_usbPath.first}/Video/$nameVideoSave.mp4';
            } else {
              usbPathh = '${_usbPath.first}/${campSchedule.urlUsp}';
            }
            print('usb path: $usbPathh');
            _controller?.dispose();
            _controller = VideoPlayerController.file(File(usbPathh));
            checkPlay = 'Chạy bằng USB';
          }
        }
        _initializeVideoPlayerFuture = _controller!.initialize();
        await _initializeVideoPlayerFuture;
        _controller!.setLooping(false);
        if (mounted) {
          setState(() {
            _controller!.play();
          });
        }
        Future.delayed(_waitTime, () async {
          if (mounted) {
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
            if (_currentIndex >= widget.campSchedules.length) {
              _currentIndex = 0; // Lặp lại từ video đầu tiên
            }
            _loadNextVideo();
          }
        });
      } catch (e) {
        print('Error loading video: $e');
        _currentIndex++;
        if (_currentIndex >= widget.campSchedules.length) {
          _currentIndex = 0; // Lặp lại từ video đầu tiên
        }
        _loadNextVideo();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        AppSP.set(AppSPKey.checkPlayVideo, 'false');
        return true; // Return true để cho phép pop màn hình
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              color: Colors.black, // Nền màu đen
            ),
            Center(
              child: _controller != null && _controller!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )
                  : Container(
                      color: Colors.black,
                    ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _formattedTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    // Text(
                    //   checkPlay,
                    //   style: const TextStyle(
                    //     color: Colors.white,
                    //     fontSize: 24,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
