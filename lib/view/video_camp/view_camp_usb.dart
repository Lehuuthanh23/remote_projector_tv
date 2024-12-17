import 'dart:async';
import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

class _VideoUSBPageState extends State<VideoUSBPage>
    with WidgetsBindingObserver {
  late Timer _timerTimeShowing;

  String _formattedTime = '';

  BetterPlayerController? _betterPlayerController;

  List<String> _videoFiles = [];
  List<String> usbPaths = [];

  int _currentVideoIndex = 0;
  bool isPlaying = false;

  double _aspectRatio = 16 / 9;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    widget.homeViewModel.setCallback(onCommandInvoke);
    _timerTimeShowing = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      _updateTime();
    });
    _loadVideos();

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _betterPlayerController?.dispose();

    _videoFiles.clear();
    usbPaths.clear();
    _timerTimeShowing.cancel();
    widget.homeViewModel.setCallback(null);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      _betterPlayerController?.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (isPlaying) {
        _betterPlayerController?.play();
      }
    }
  }

  void onCommandInvoke(String command) {
    if (command == AppString.pauseVideo) {
      isPlaying = !isPlaying;
      if (isPlaying) {
        _betterPlayerController?.pause();
      } else {
        _betterPlayerController?.play();
      }
    } else if (command == AppString.stopVideo) {
      Navigator.pop(context);
    }
  }

  Future<void> _setupVideo(String url) async {
    BetterPlayerConfiguration betterPlayerConfiguration =
        const BetterPlayerConfiguration(
      autoPlay: true,
      looping: false,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        showControls: false,
      ),
    );

    BetterPlayerDataSource betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.file,
      url,
    );

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController!.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
        _playNextVideo();
      }
    });
    await _betterPlayerController!
        .setupDataSource(betterPlayerDataSource)
        .then((_) async {
      final videoPlayerController =
          _betterPlayerController!.videoPlayerController;
      double ratio = 16 / 9;
      if (videoPlayerController != null) {
        final size = videoPlayerController.value.size;
        if (size != null) {
          ratio = size.width / size.height;
        }
      }

      _aspectRatio = ratio;
    });
    setState(() {});
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

  bool _isImage(String path) {
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif');
  }

  Future<void> _loadVideos() async {
    await _getUsbPath();
    final videosDirectory = Directory('${usbPaths.first}/Videos');
    final pictureDirectory = Directory('${usbPaths.first}/Images');
    final videoFiles = videosDirectory
        .listSync()
        .where((item) => item.path.endsWith('.mp4'))
        .map((item) => item.path)
        .toList();
    final imageFiles = pictureDirectory
        .listSync()
        .where((item) => _isImage(item.path))
        .map((item) => item.path)
        .toList();
    videoFiles.addAll(imageFiles);
    if (videoFiles.isNotEmpty) {
      _videoFiles = videoFiles;
      _initializeVideoPlayer();
    }
  }

  void _initializeVideoPlayer() {
    if (_videoFiles.isNotEmpty) {
      _setupVideo(_videoFiles[_currentVideoIndex]);
    }
  }

  void _playNextVideo() {
    _currentVideoIndex = (_currentVideoIndex + 1) % _videoFiles.length;
    if (_isImage(_videoFiles[_currentVideoIndex])) {
      _showImage(_videoFiles[_currentVideoIndex]);
    } else {
      _setupVideo(_videoFiles[_currentVideoIndex]);
    }
  }

  Future<void> _showImage(String imagePath) async {
    // Hiển thị ảnh trong 10 giây
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(0),
          child: Image.file(
            File(imagePath),
            fit: BoxFit.cover,
          ),
        );
      },
    );

    // Sau 10 giây, đóng dialog và chuyển sang video tiếp theo
    await Future.delayed(const Duration(seconds: 10));
    Navigator.of(context, rootNavigator: true).pop(); // Đóng dialog
    _playNextVideo(); // Chuyển sang video kế tiếp
  }

  void _updateTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final formattedTime = DateFormat('HH:mm:ss').format(now);
    setState(() {
      _formattedTime = formattedTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Center(
              child: _betterPlayerController != null
                  ? AspectRatio(
                      aspectRatio: _aspectRatio,
                      child: BetterPlayer(controller: _betterPlayerController!),
                    )
                  : null,
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.all(10),
                child: Text(
                  _formattedTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
