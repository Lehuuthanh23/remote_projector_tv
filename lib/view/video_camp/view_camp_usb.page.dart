import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;

class VideoPlayerWidget extends StatefulWidget {
  final String customPath;

  VideoPlayerWidget({Key? key, required this.customPath}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  List<File> videoFiles = [];
  int currentIndex = 0;
  bool isSingleFile = false;
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

  Future<void> _initializeVideoPlayer(String customPath) async {
    // Lấy đường dẫn tới USB
    await _getUsbPath();
    usbPathh = '$_usbPath/$customPath';

    final File file = File(usbPathh);
    if (file.existsSync()) {
      // Nếu đường dẫn là một file
      isSingleFile = true;
      setState(() {
        videoFiles = [file];
      });
      _playVideo(0);
    } else {
      // Nếu đường dẫn là một thư mục
      final Directory directory = Directory(usbPathh);
      if (directory.existsSync()) {
        setState(() {
          videoFiles = directory
              .listSync()
              .where((file) => path.extension(file.path).toLowerCase() == '.mp4')
              .map((file) => File(file.path))
              .toList();
          isSingleFile = false;
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
        ..setLooping(false) // Không lặp lại từng video
        ..addListener(() {
          if (_controller!.value.position == _controller!.value.duration) {
            if (currentIndex + 1 >= videoFiles.length) {
              currentIndex = 0; // Quay lại video đầu tiên
            } else {
              currentIndex++;
            }
            _playVideo(currentIndex);
          }
        });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer(widget.customPath);
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
