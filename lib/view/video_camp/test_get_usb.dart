import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../models/camp/camp_schedule.dart';

class VideoPlayerFromCampSchedule extends StatefulWidget {
  final List<CampSchedule> campSchedules;
  final String lstCampScheduleString;
  VideoPlayerFromCampSchedule(
      {Key? key,
      required this.campSchedules,
      required this.lstCampScheduleString})
      : super(key: key);

  @override
  _VideoPlayerFromCampScheduleState createState() =>
      _VideoPlayerFromCampScheduleState();
}

class _VideoPlayerFromCampScheduleState
    extends State<VideoPlayerFromCampSchedule> {
  VideoPlayerController? _controller;
  late Future<void> _initializeVideoPlayerFuture;
  int _currentIndex = 0;
  static const platform = MethodChannel('com.example.usb/serial');
  List<String> _usbPath = [];
  String nameVideo = '';
  List<String> nameCamp = [];
  @override
  void initState() {
    print('Số lượng camp: ${widget.campSchedules.length}');
    widget.campSchedules.forEach((camp) {
      print('Campp: ${camp.campaignName}');
      nameCamp.add(camp.campaignName);
    });
    super.initState();
    _loadNextVideo();
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

    setState(() {
      _usbPath = usbPath;
    });
  }

  Future<void> _loadNextVideo() async {
    if (_currentIndex < widget.campSchedules.length) {
      final campSchedule = widget.campSchedules[_currentIndex];
      nameVideo = campSchedule.campaignName;
      try {
        if (campSchedule.videoType == 'url') {
          print('vào video: $nameVideo');
          _controller?.dispose();
          _controller = VideoPlayerController.networkUrl(
              Uri.parse(campSchedule.urlYoutube));
        } else {
          await _getUsbPath();
          String usbPathh = '${_usbPath.first}/${campSchedule.urlUsp}';
          print('usb path: $usbPathh');
          _controller?.dispose();
          _controller = VideoPlayerController.file(File(usbPathh));
        }
        _initializeVideoPlayerFuture = _controller!.initialize();
        await _initializeVideoPlayerFuture;
        _controller!.setLooping(false);
        setState(() {
          _controller!.play();
        });
        // Đặt thời gian chờ 15 giây trước khi chuyển sang video tiếp theo
        Future.delayed(Duration(seconds: 15), () {
          _currentIndex++;
          if (_currentIndex >= widget.campSchedules.length) {
            _currentIndex = 0; // Lặp lại từ video đầu tiên
          }
          _loadNextVideo();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        ],
      ),
    );
  }
}
