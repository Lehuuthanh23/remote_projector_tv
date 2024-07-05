import 'dart:isolate';
import 'package:dio/dio.dart';

class VideoDownloader {
  static void downloadVideo(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final message in port) {
      final url = message[0];
      final filePath = message[1];
      final replyPort = message[2];

      try {
        final dio = Dio();
        await dio.download(
          url,
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = received / total;
              replyPort.send(progress);
            }
          },
        );
        replyPort.send("Completed");
      } catch (e) {
        replyPort.send("Error: $e");
      }
    }
  }

  static Future<void> startDownload(
      String url, String savePath, Function(double) onProgress) async {
    final port = ReceivePort();
    final isolate = await Isolate.spawn(downloadVideo, port.sendPort);

    final sendPort = await port.first as SendPort;
    final replyPort = ReceivePort();

    sendPort.send([url, savePath, replyPort.sendPort]);

    await for (final progress in replyPort) {
      if (progress is double) {
        onProgress(progress);
      } else {
        isolate.kill(priority: Isolate.immediate);
        break;
      }
    }
  }
}
