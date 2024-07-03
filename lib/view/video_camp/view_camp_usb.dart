import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VideoUSBPage extends StatefulWidget {
  @override
  _VideoUSBPageState createState() => _VideoUSBPageState();
}

class _VideoUSBPageState extends State<VideoUSBPage> {
  late VideoPlayerController _controller;
  List<File> _videoFiles = [];
  int _currentVideoIndex = 0;
  bool isPlaying = false;
  List<String> usbPaths = [];
  static const platform = MethodChannel('com.example.usb/serial');

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _getUsbPath() async {
    List<String> usbPath = [];
    var result = await platform.invokeMethod('getUsbPath');
    for (var path in result) {
      usbPath.add(path.toString());
    }
    setState(() {
      usbPaths = usbPath;
    });
  }

  Future<void> _loadVideos() async {
    await _getUsbPath();
    final videosDirectory = Directory('${usbPaths.first}/Videos');
    final videoFiles = videosDirectory
        .listSync()
        .where((item) => item.path.endsWith('.mp4'))
        .map((item) => File(item.path))
        .toList();

    if (videoFiles.isNotEmpty) {
      setState(() {
        _videoFiles = videoFiles;
      });
      _initializeVideoPlayer();
    }
  }

  void _initializeVideoPlayer() {
    if (_videoFiles.isNotEmpty) {
      _controller = VideoPlayerController.file(_videoFiles[_currentVideoIndex])
        ..addListener(() {
          if (_controller.value.position == _controller.value.duration) {
            _playNextVideo();
          }
          setState(() {});
        })
        ..setLooping(false)
        ..initialize().then((_) {
          setState(() {});
          _controller.play();
          isPlaying = true;
        });
    }
  }

  void _playNextVideo() {
    _currentVideoIndex = (_currentVideoIndex + 1) % _videoFiles.length;
    _controller.dispose();
    _controller = VideoPlayerController.file(_videoFiles[_currentVideoIndex])
      ..addListener(() {
        if (_controller.value.position == _controller.value.duration) {
          _playNextVideo();
        }
        setState(() {});
      })
      ..setLooping(false)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : Container(
                color: Colors.black,
              ),
      ),
    );
  }
}
