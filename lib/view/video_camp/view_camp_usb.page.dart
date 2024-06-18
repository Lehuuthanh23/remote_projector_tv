import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ViewCampUSBPage extends StatefulWidget {
  @override
  _ViewCampUSBPageState createState() => _ViewCampUSBPageState();
}

class _ViewCampUSBPageState extends State<ViewCampUSBPage> {
  VideoPlayerController? _controller;
  List<File> videoFiles = [];
  int currentIndex = 0;
  String usbPathh = 'Không có';

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  static const platform = MethodChannel('com.example.usb/serial');

  String _usbPath = 'Unknown';

  Future<void> _getUsbPath() async {
    String usbPath;
    try {
      final String result = await platform.invokeMethod('getUsbPath');
      usbPath = result;
    } on PlatformException catch (e) {
      usbPath = "Failed to get USB path: '${e.message}'.";
    }

    setState(() {
      _usbPath = usbPath;
    });
  }

  Future<void> _loadVideosFromDirectory() async {
    // Lấy đường dẫn tới USB
    await _getUsbPath();
    usbPathh = '$_usbPath/Video/';
    //usbPathh = '/storage/7432-760A/Video/';
    final Directory directory = Directory(usbPathh);
    if (directory.existsSync()) {
      setState(() {
        videoFiles = directory
            .listSync()
            .where((file) => path.extension(file.path).toLowerCase() == '.mp4')
            .map((file) => File(file.path))
            .toList();
      });

      if (videoFiles.isNotEmpty) {
        _playVideo(0);
      }
    } else {
      setState(() {
        videoFiles = [];
      });
    }
  }

  void _playVideo(int index) {
    if (index >= 0 && index < videoFiles.length) {
      _controller?.dispose();
      _controller = VideoPlayerController.file(videoFiles[index])
        ..initialize().then((_) {
          setState(() {
            _controller?.play();
          });
        })
        ..setLooping(false)
        ..addListener(() {
          if (_controller!.value.position == _controller!.value.duration) {
            if (currentIndex + 1 >= videoFiles.length) {
              currentIndex = 0;
              _playVideo(0);
            } else {
              _playVideo(++currentIndex);
            }
          }
        });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadVideosFromDirectory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _controller == null
            ? Text('Đường dẫn: $usbPathh')
            : _controller!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  )
                : const CircularProgressIndicator(),
      ),
    );
  }
}
