import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

import '../../app/app_string.dart';
import '../../app/app_utils.dart';
import '../../view_models/home.vm.dart';

class VideoUSBPage extends StatefulWidget {
  final HomeViewModel homeViewModel;

  const VideoUSBPage({
    super.key,
    required this.homeViewModel,
  });

  @override
  State<VideoUSBPage> createState() => _VideoUSBPageState();
}

class _VideoUSBPageState extends State<VideoUSBPage> with WidgetsBindingObserver {
  late VideoPlayerController _controller;

  List<File> _videoFiles = [];
  List<String> usbPaths = [];

  int _currentVideoIndex = 0;
  bool isPlaying = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    widget.homeViewModel.setCallback(onCommandInvoke);

    _loadVideos();

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();

    _videoFiles.clear();
    usbPaths.clear();
    widget.homeViewModel.setCallback(null);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (isPlaying) {
        _controller.play();
      }
    }
  }

  void onCommandInvoke(String command) {
    if (command == AppString.pauseVideo) {
      isPlaying = !isPlaying;
      if (isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    } else if (command == AppString.stopVideo) {
      Navigator.pop(context);
    }
  }

  Future<void> _getUsbPath() async {
    List<String> usbPath = [];
    var result = await AppUtils.platformChannel.invokeMethod('getUsbPath');
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
