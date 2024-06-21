import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../models/camp/camp_schedule.dart';

class ViewCampUSBPage extends StatefulWidget {
  final CampSchedule campSchedule;

  ViewCampUSBPage({Key? key, required this.campSchedule}) : super(key: key);

  @override
  _ViewCampUSBPageState createState() => _ViewCampUSBPageState();
}

class _ViewCampUSBPageState extends State<ViewCampUSBPage> {
  VideoPlayerController? _uspController;
  List<File> videoFiles = [];
  int currentIndex = 0;
  String usbPathh = 'Không có';
  @override
  void dispose() {
    _uspController?.dispose();
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

  Future<void> _requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      _loadVideosFromDirectory();
    } else {
      // Quyền không được cấp
      print('Quyền truy cập bộ nhớ không được cấp');
    }
  }

  Future<void> _loadVideosFromDirectory() async {
    // Lấy đường dẫn tới USB
    await _getUsbPath();
    usbPathh = '$_usbPath/${widget.campSchedule.urlUsp}';

    final File file = File(usbPathh);
    if (file.existsSync()) {
      // Nếu đường dẫn là một file
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
              .where(
                  (file) => path.extension(file.path).toLowerCase() == '.mp4')
              .map((file) => File(file.path))
              .toList();
        });

        if (videoFiles.isNotEmpty) {
          _playVideo(0);
          if (videoFiles.isNotEmpty) {
            _playVideo(0);
          }
        } else {
          setState(() {
            videoFiles = [];
          });
        }
      } else {
        setState(() {
          videoFiles = [];
        });
      }
    }
    //}
  }

  void _playVideo(int index) {
    if (index >= 0 && index < videoFiles.length) {
      _uspController?.dispose();
      _uspController = VideoPlayerController.file(videoFiles[index])
        ..initialize().then((_) {
          setState(() {
            _uspController?.play();
          });
        })
        ..setLooping(false)
        ..addListener(() {
          if (_uspController!.value.position ==
              _uspController!.value.duration) {
            Navigator.pop(context);
          }
        });
    }
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _uspController == null
            ? Text('Đường dẫn: $usbPathh')
            : _uspController!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _uspController!.value.aspectRatio,
                    child: VideoPlayer(_uspController!),
                  )
                : Positioned.fill(
                    child: Container(
                      color: Colors.black,
                    ),
                  ),
      ),
    );
  }
}
