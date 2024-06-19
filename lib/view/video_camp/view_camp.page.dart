// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:flutter/services.dart'
//     show MethodChannel, PlatformException, rootBundle;
// import 'package:path/path.dart' as path;

// import '../../models/camp/camp_schedule.dart';

// class ViewCampPage extends StatefulWidget {
//   final List<CampSchedule> lstCampSchedule;

//   ViewCampPage({Key? key, required this.lstCampSchedule}) : super(key: key);

//   @override
//   _ViewCampPageState createState() => _ViewCampPageState();
// }

// class _ViewCampPageState extends State<ViewCampPage> {
//   late final WebViewController _webViewController;
//   VideoPlayerController? _videoController;
//   int _currentVideoIndex = 0;
//   List<String> lstVideoUrl = [];
//   List<File> videoFiles = [];
//   String usbPathh = 'Không có';
//   late Duration _waitTime;
//   bool _showBlackOverlay = true;
//   static const platform = MethodChannel('com.example.usb/serial');
//   String _usbPath = 'Unknown';
//   int currentIndex = 0;
//   bool isSingleFile = false;
//   Future<void> _getUsbPath() async {
//     String usbPath;
//     try {
//       final String result = await platform.invokeMethod('getUsbPath');
//       usbPath = result;
//     } on PlatformException catch (e) {
//       usbPath = "Failed to get USB path: '${e.message}'.";
//     }

//     setState(() {
//       _usbPath = usbPath;
//     });
//   }

//   Future<void> _initializeVideoPlayer(String customPath) async {
//     // Lấy đường dẫn tới USB
//     await _getUsbPath();
//     usbPathh = '$_usbPath/$customPath';

//     final File file = File(usbPathh);
//     if (file.existsSync()) {
//       // Nếu đường dẫn là một file
//       isSingleFile = true;
//       setState(() {
//         videoFiles = [file];
//       });
//       _playVideo(0);
//     } else {
//       // Nếu đường dẫn là một thư mục
//       final Directory directory = Directory(usbPathh);
//       if (directory.existsSync()) {
//         setState(() {
//           videoFiles = directory
//               .listSync()
//               .where(
//                   (file) => path.extension(file.path).toLowerCase() == '.mp4')
//               .map((file) => File(file.path))
//               .toList();
//           isSingleFile = false;
//         });

//         if (videoFiles.isNotEmpty) {
//           _playVideo(0);
//         } else {
//           _currentVideoIndex++;
//         }
//       } else {
//         setState(() {
//           videoFiles = [];
//         });
//         _currentVideoIndex++;
//       }
//     }
//   }

//   void _playVideo(int index) {
//     if (index >= 0 && index < videoFiles.length) {
//       _videoController?.dispose();
//       _videoController = VideoPlayerController.file(videoFiles[index])
//         ..initialize().then((_) {
//           setState(() {
//             _videoController?.play();
//           });
//         })
//         ..setLooping(false) // Không lặp lại từng video
//         ..addListener(() {
//           if (_videoController!.value.position ==
//               _videoController!.value.duration) {
//             if (currentIndex + 1 >= videoFiles.length) {
//               currentIndex = 0;
//             } else {
//               currentIndex++;
//             }
//             _playVideo(currentIndex);
//           }
//         });
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     lstVideoUrl =
//         widget.lstCampSchedule.map((camp) => camp.urlYoutube).toList();
//     _webViewController = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(const Color(0x00000000))
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onProgress: (int progress) {},
//           onPageStarted: (String url) {},
//           onPageFinished: (String url) {},
//           onHttpError: (HttpResponseError error) {},
//           onWebResourceError: (WebResourceError error) {},
//           onNavigationRequest: (NavigationRequest request) {
//             if (request.url.startsWith('https://www.youtube.com/')) {
//               return NavigationDecision.prevent;
//             }
//             return NavigationDecision.navigate;
//           },
//         ),
//       );
//     _checkAndLoadContent(_currentVideoIndex);
//   }

//   void _checkAndLoadContent(int index) {
//     if (index >= widget.lstCampSchedule.length) {
//       _currentVideoIndex = 0;
//       _checkAndLoadContent(_currentVideoIndex);
//       return;
//     }

//     final camp = widget.lstCampSchedule[index];
//     _waitTime = Duration(seconds: int.parse(camp.videoDuration));

//     if (camp.videoType == 'url') {
//       _loadHtmlFromAssets(index);
//     } else {
//       _initializeVideoPlayer(camp.urlUsp);
//     }
//   }

//   void _loadHtmlFromAssets(int index) async {
//     String filePath = 'assets/abc.html';
//     String fileText = await rootBundle.loadString(filePath);
//     String updatedFileText =
//         fileText.replaceAll("link_video", lstVideoUrl[index]);
//     _webViewController.loadRequest(
//       Uri.dataFromString(
//         updatedFileText,
//         mimeType: 'text/html',
//         encoding: Encoding.getByName('utf-8'),
//       ),
//     );

//     setState(() {
//       _showBlackOverlay = true;
//     });

//     Future.delayed(const Duration(seconds: 2), () {
//       setState(() {
//         _showBlackOverlay = false;
//       });

//       Future.delayed(_waitTime, () {
//         _currentVideoIndex++;
//         _checkAndLoadContent(_currentVideoIndex);
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _webViewController.clearCache();
//     _videoController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           if (_currentVideoIndex < widget.lstCampSchedule.length &&
//               widget.lstCampSchedule[_currentVideoIndex].videoType == 'url')
//             WebViewWidget(controller: _webViewController)
//           else
//             Center(
//               child: _videoController == null
//                   ? Text('Đường dẫn: $usbPathh')
//                   : _videoController!.value.isInitialized
//                       ? AspectRatio(
//                           aspectRatio: _videoController!.value.aspectRatio,
//                           child: VideoPlayer(_videoController!),
//                         )
//                       : const CircularProgressIndicator(),
//             ),
//           if (_showBlackOverlay)
//             Positioned.fill(
//               child: Container(
//                 color: Colors.black,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// import '../../models/camp/camp_schedule.dart';

// class ReviewVideoPage extends StatefulWidget {
//   final List<CampSchedule> lstCampSchedule;
//   ReviewVideoPage({super.key, required this.lstCampSchedule});

//   @override
//   State<ReviewVideoPage> createState() => _ReviewVideoPageState();
// }

// class _ReviewVideoPageState extends State<ReviewVideoPage> {
//   YoutubePlayerController? _controller;
//   List<String> lstVideoUrl = [];
//   int _currentVideoIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     lstVideoUrl =
//         widget.lstCampSchedule.map((camp) => camp.urlYoutube).toList();
//     _loadVideo(_currentVideoIndex);
//   }

//   void _loadVideo(int index) {
//     if (index >= lstVideoUrl.length) {
//       _currentVideoIndex = 0;
//       _loadVideo(_currentVideoIndex);
//       return;
//     }

//     final videoUrl = lstVideoUrl[index];
//     final videoID =
//         YoutubePlayer.convertUrlToId(videoUrl) ?? getYoutubeVideoId(videoUrl);

//     if (videoID == null) {
//       WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
//         Navigator.pop(context, true);
//       });
//     } else {
//       if (_controller != null) {
//         _controller!.dispose();
//       }
//       _controller = YoutubePlayerController(
//         initialVideoId: videoID,
//         flags: const YoutubePlayerFlags(
//           autoPlay: true,
//           captionLanguage: 'vi',
//           forceHD: true,
//           loop: false,
//         ),
//       )..addListener(_videoListener);
//     }
//   }

//   void _videoListener() {
//     if (_controller != null &&
//         _controller!.value.playerState == PlayerState.ended) {
//       _currentVideoIndex++;
//       _loadVideo(_currentVideoIndex);
//     }
//   }

//   @override
//   void dispose() {
//     if (_controller != null) {
//       _controller!.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: WillPopScope(
//         onWillPop: () {
//           popTap();

//           return Future.value(false);
//         },
//         child: Stack(
//           children: [
//             SizedBox(
//               height: MediaQuery.of(context).size.height,
//               width: MediaQuery.of(context).size.width,
//               child: Center(
//                 child: _controller != null
//                     ? YoutubePlayer(
//                         controller: _controller!,
//                         showVideoProgressIndicator: true,
//                       )
//                     : null,
//               ),
//             ),
//             Positioned(
//               right: 20,
//               top: 40,
//               child: IconButton(
//                 onPressed: () => popTap(closePage: true),
//                 color: Colors.white,
//                 icon: const Icon(
//                   Icons.close,
//                   color: Colors.white,
//                   size: 35,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void popTap({bool closePage = false}) {
//     if (_controller?.value.isFullScreen == true) {
//       _controller!.toggleFullScreenMode();
//       if (closePage) {
//         Navigator.pop(context);
//       }
//     } else {
//       Navigator.pop(context);
//     }
//   }

//   String? getYoutubeVideoId(String url) {
//     RegExp regExp = RegExp(
//         r'^https?://(?:www\.)?youtube\.com/live/([_\-a-zA-Z0-9]{11}).*$');

//     Match? match = regExp.firstMatch(url);

//     if (match != null && match.groupCount >= 1) {
//       return match.group(1);
//     } else {
//       return null;
//     }
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../models/camp/camp_schedule.dart';

class ViewCampPage extends StatefulWidget {
  final List<CampSchedule> lstCampSchedule;

  ViewCampPage({Key? key, required this.lstCampSchedule}) : super(key: key);

  @override
  _ViewCampPageState createState() => _ViewCampPageState();
}

class _ViewCampPageState extends State<ViewCampPage> {
  late final WebViewController _controller;
  int _currentVideoIndex = 0;
  List<String> lstVideoUrl = [];
  late Duration _waitTime; // Thời gian chờ trước khi chuyển video
  bool _showBlackOverlay =
      true; // Biến để theo dõi khi nào nên hiển thị màn hình đen

  @override
  void initState() {
    super.initState();
    lstVideoUrl =
        widget.lstCampSchedule.map((camp) => camp.urlYoutube).toList();
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

    _loadHtmlFromAssets(_currentVideoIndex);
  }

  void _loadHtmlFromAssets(int index) async {
    print('Vào _loadHtmlFromAssets');
    if (index >= lstVideoUrl.length) {
      _currentVideoIndex = 0;
      _loadHtmlFromAssets(_currentVideoIndex);
    }

    _waitTime = Duration(
        seconds: int.parse(widget.lstCampSchedule[index].videoDuration));
    String filePath = 'assets/abc.html';
    String fileText = await rootBundle.loadString(filePath);
    print('Nội dung file: $fileText');
    String updatedFileText = fileText.replaceAll(
      "link_video",
     //lstVideoUrl[index],
     '/storage/7432-760A/Video/galaxy_s24_ultra.mp4'
    );
    print('Nội dung file sau replace: $updatedFileText');
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

      Future.delayed(_waitTime, () {
        _currentVideoIndex++;
        _loadHtmlFromAssets(_currentVideoIndex);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_showBlackOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}
