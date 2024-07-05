import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import '../app/app_utils.dart';
import 'video_camp/video_downloader.dart';

class VideoDownloaderScreen extends StatefulWidget {
  @override
  _VideoDownloaderScreenState createState() => _VideoDownloaderScreenState();
}

class _VideoDownloaderScreenState extends State<VideoDownloaderScreen> {
  TextEditingController _urlController = TextEditingController();
  double _progress = 0.0;
  String _progressString = "0%";
  List<String> usbPath = [];
  String urlVideo = 'https://web5sao.net/media/SamsungGalaxy-S24-Ultra.mp4';
  Future<void> _getUsbPath() async {
    try {
      var result = await AppUtils.platformChannel.invokeMethod('getUsbPath');
      for (var path in result) {
        usbPath.add(path.toString());
      }
    } on PlatformException catch (e) {
      print('Lỗi: $e');
    }
  }

  Future<void> _downloadVideo(String url) async {
    Directory? directory;
    try {
      // Request storage permissions
      if (await Permission.storage.request().isGranted) {
        // Get the USB directory
        await _getUsbPath();
        directory = Directory("${usbPath.first}/Video");
        String nameVideo = urlVideo.split('/').last.split('.').first.toString();
        print('Name video: $nameVideo');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        String savePath = path.join(directory.path, '$nameVideo.mp4');
        // File saveFile = File('${directory.path}/$nameVideo.mp4');
        // Dio dio = Dio();

        // await dio.download(
        //   url,
        //   saveFile.path,
        //   onReceiveProgress: (received, total) {
        //     if (total != -1) {
        //       setState(() {
        //         _progress = received / total;
        //         _progressString = "${(_progress * 100).toStringAsFixed(0)}%";
        //       });
        //     }
        //   },
        // );

        await VideoDownloader.startDownload(url, savePath, (progress) {
          setState(() {
            _progress = progress;
          });
        });
      } else {
        // Handle permission denial
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied')),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    _urlController.text = urlVideo;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Downloader"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: "Video URL",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _downloadVideo(_urlController.text);
              },
              child: const Text("Download Video"),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              color: Colors.blue,
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text(
              'Download Progress: $_progressString',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
