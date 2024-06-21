import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart'
    show MethodChannel, PlatformException, rootBundle;
import 'package:path/path.dart' as path;
import '../../models/camp/camp_schedule.dart';

class ViewCampPage extends StatefulWidget {
  final List<CampSchedule> lstCampSchedule;

  ViewCampPage({Key? key, required this.lstCampSchedule}) : super(key: key);

  @override
  _ViewCampPageState createState() => _ViewCampPageState();
}

class _ViewCampPageState extends State<ViewCampPage> {
  late final WebViewController _controller;
  late VideoPlayerController _uspController;
  int _currentVideoIndex = 0;
  late Duration _waitTime;
  bool _showBlackOverlay = true;
  String usbPathh = 'Không có';
  String fileText = '';
  String updatedFileText = '';
  String check = '';

  static const platform = MethodChannel('com.example.usb/serial');

  List<String> _usbPath = [];

  Future<void> _getUsbPath() async {
    List<String> usbPath = [];
    try {
      List<String> result = await platform.invokeMethod('getUsbPath');
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

  void _loadHtmlFromAssets(String url) async {
    print('Vào _loadHtmlFromAssets');
    _waitTime = Duration(
        seconds: int.parse(
            widget.lstCampSchedule[_currentVideoIndex].videoDuration));
    String filePath = 'assets/abc.html';
    fileText = await rootBundle.loadString(filePath);
    updatedFileText = fileText.replaceAll(
      "link_video",
      url,
    );
    print('Nội dung file sau replace: $fileText');
    _controller.loadRequest(
      Uri.dataFromString(
        updatedFileText,
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8'),
      ),
    );

    setState(() {
      _showBlackOverlay = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showBlackOverlay = false;
      });
      print('Thời gian chờ video: ${_waitTime.inSeconds}');
      Future.delayed(_waitTime, () {
        if (_currentVideoIndex + 1 < widget.lstCampSchedule.length) {
          _currentVideoIndex++;
          _navigateCampSchedule(_currentVideoIndex);
        } else {
          if (_currentVideoIndex + 1 == widget.lstCampSchedule.length) {
            _currentVideoIndex = 0;
            _navigateCampSchedule(_currentVideoIndex);
          }
        }
      });
    });
  }

  Future<void> _loadVideosFromDirectory(String urlUsp) async {
    // Lấy đường dẫn tới USB
    await _getUsbPath();
    usbPathh = '${_usbPath.first}/$urlUsp';
    check = 'usp path: $usbPathh';
    final File file = File(usbPathh);
    if (file.existsSync()) {
      // Nếu đường dẫn là một file
      setState(() {
        _uspController = VideoPlayerController.file(file);
      });
      _playVideo();
    } else {
      check = '$check / không có file';
    }
  }

  void _playVideo() {
    _uspController.initialize().then((_) {
      setState(() {
        _uspController.play();
      });
      _waitTime = Duration(
          seconds: int.parse(
              widget.lstCampSchedule[_currentVideoIndex].videoDuration));
      _uspController.addListener(() {
        //if (_uspController.value.position == _uspController.value.duration) {
        Future.delayed(_waitTime, () {
          if (_currentVideoIndex + 1 < widget.lstCampSchedule.length) {
            _currentVideoIndex++;
            _navigateCampSchedule(_currentVideoIndex);
          } else {
            if (_currentVideoIndex + 1 == widget.lstCampSchedule.length) {
              _currentVideoIndex = 0;
              _navigateCampSchedule(_currentVideoIndex);
            }
          }
        });
        // }
      });
    });
  }

  void _navigateCampSchedule(int index) {
    if (widget.lstCampSchedule[index].videoType == 'url') {
      _loadHtmlFromAssets(widget.lstCampSchedule[index].urlYoutube);
    } else {
      _loadVideosFromDirectory(widget.lstCampSchedule[index].urlUsp);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    _navigateCampSchedule(_currentVideoIndex);
  }

  @override
  void dispose() {
    _uspController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          widget.lstCampSchedule[_currentVideoIndex].videoType == 'url'
              ? WebViewWidget(controller: _controller)
              : _uspController.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _uspController.value.aspectRatio,
                      child: VideoPlayer(_uspController),
                    )
                  : const Text(
                      'Khoong cos usb',
                      style: TextStyle(color: Colors.red),
                    ),
          Text('Check: $check')
        ],
      ),
    );
  }
}
