import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class VideoDownloaderScreen extends StatefulWidget {
  @override
  _VideoDownloaderScreenState createState() => _VideoDownloaderScreenState();
}

class _VideoDownloaderScreenState extends State<VideoDownloaderScreen> {
  TextEditingController _urlController = TextEditingController();
  double _progress = 0.0;
  String _progressString = "0%";
  static const platform = MethodChannel('com.example.usb/serial');
  String _usbPath = '';

  Future<void> _getUsbPath() async {
    try {
      final String result = await platform.invokeMethod('getUsbPath');
      setState(() {
        _usbPath = result;
      });
    } on PlatformException catch (e) {
      print("Failed to get USB path: '${e.message}'.");
    }
  }

  Future<void> _downloadVideo(String url) async {
    Directory? directory;
    try {
      // Request storage permissions
      if (await Permission.storage.request().isGranted) {
        // Get the USB directory
        await _getUsbPath();
        directory = Directory(_usbPath + "/Video");

        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        File saveFile = File('${directory.path}/videodemo.mp4');
        Dio dio = Dio();

        await dio.download(
          url,
          saveFile.path,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              setState(() {
                _progress = received / total;
                _progressString = (_progress * 100).toStringAsFixed(0) + "%";
              });
            }
          },
        );
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
    _urlController.text = 'https://web5sao.net/media/AppleiPhone15-Pro.mp4';
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

void main() {
  runApp(MaterialApp(
    home: VideoDownloaderScreen(),
  ));
}
