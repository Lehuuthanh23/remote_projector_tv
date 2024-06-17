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

class HtmlViewerPage extends StatefulWidget {
  final List<CampSchedule> lstCampSchedule;

  HtmlViewerPage({Key? key, required this.lstCampSchedule}) : super(key: key);

  @override
  _HtmlViewerPageState createState() => _HtmlViewerPageState();
}

class _HtmlViewerPageState extends State<HtmlViewerPage> {
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
    if (index >= lstVideoUrl.length) {
      _currentVideoIndex = 0;
      _loadHtmlFromAssets(_currentVideoIndex);
      return;
    }

    _waitTime = Duration(
        seconds: int.parse(widget.lstCampSchedule[index].videoDuration));

    String filePath = 'assets/abc.html';
    String fileText = await rootBundle.loadString(filePath);

    // Thực hiện thay đổi nội dung HTML
    String updatedFileText = fileText.replaceAll(
      "link_video",
      lstVideoUrl[index],
    );

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
