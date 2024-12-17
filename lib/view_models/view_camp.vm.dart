import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../app/app_sp.dart';
import '../app/app_sp_key.dart';
import '../app/app_string.dart';
import '../app/app_utils.dart';
import '../models/camp/camp_schedule.dart';
import '../observer/navigator_observer.dart';
import '../request/camp/camp.request.dart';
import '../services/usb.service.dart';
import '../view/video_camp/video_downloader.dart';
import 'home.vm.dart';

class ViewCampViewModel extends BaseViewModel {
  ViewCampViewModel({
    required this.context,
    required this.homeViewModel,
  });

  final BuildContext context;
  final HomeViewModel homeViewModel;

  static const usbEventChannel = EventChannel('com.example.usb/event');
  final Dio _dio = Dio();

  BetterPlayerController? _betterPlayerController;
  BetterPlayerController? get betterPlayerController => _betterPlayerController;

  bool isDrawerOpen = false;

  String _formattedTime = '';
  String get formattedTime => _formattedTime;

  final Set<String> _setCampaignError = {};
  Set<String> get setCampaignError => _setCampaignError;

  double _aspectRatio = 16 / 9;
  double get aspectRatio => _aspectRatio;

  late Timer _timerTimeShowing;

  List<String> usbPaths = [];
  List<CampSchedule> campSchedulesNew = [];
  File? image;
  String proUN = '';
  String proPW = '';
  String projectorIP = '';
  String offProjector = '';
  String onProjector = '';
  int currentIndex = 0;
  int _waitTime = 0;
  int routerStackLength = 0;

  bool? checkDisconnectUSB;
  bool? checkPacket;
  bool isPlaying = true;
  bool flagPlayCamp = false;
  bool pauseVideo = false;
  bool checkImage = false;
  bool checkAlive = true;
  bool isDisposeVideoPlayer = false;

  StreamSubscription? _subscription;
  FocusNode drawerFocus = FocusNode();

  void init() {
    checkAlive = true;
    proUN = AppSP.get(AppSPKey.proUN) ?? '';
    proPW = AppSP.get(AppSPKey.proPW) ?? '';
    projectorIP = AppSP.get(AppSPKey.projectorIP) ?? '';
    offProjector =
        'http://$proUN:$proPW@$projectorIP/cgi-bin/sd95.cgi?cm=0200a13d0203';
    onProjector =
        "http://$proUN:$proPW@$projectorIP/cgi-bin/sd95.cgi?cm=0200a13d0103";

    _timerTimeShowing = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      checkNumberOfPages(context);
      getCampSchedule();

      String? lstCampScheduleString = AppSP.get(AppSPKey.lstCampSchedule);
      List<dynamic> lstCampScheduleJson = jsonDecode(lstCampScheduleString!);
      DateTime now = DateTime.now().toUtc().add(const Duration(hours: 7));

      if (lstCampScheduleJson
          .map((e) => CampSchedule.fromJson(e))
          .where((camp) {
            DateTime fromTime = stringToDateTime(camp.fromTime);
            DateTime toTime = stringToDateTime(camp.toTime);
            return fromTime.isBefore(now) &&
                toTime.isAfter(now) &&
                camp.status == '1' &&
                AppString.checkPacket;
          })
          .toList()
          .isEmpty) {
        if (isPlaying) {
          isPlaying = false;
          flagPlayCamp = false;
          _betterPlayerController?.pause();
          _betterPlayerController = null;
          notifyListeners();
        }
      } else {
        if (AppSP.get(AppSPKey.turnOnlPJ) == 'true') {
          _dio.get(onProjector);
        }

        if (!flagPlayCamp) {
          isPlaying = true;
          notifyListeners();
          _loadNextMedia(campSchedulesNew);
          flagPlayCamp = true;
          notifyListeners();
        }
      }
      _updateTime();
    });

    _subscription =
        usbEventChannel.receiveBroadcastStream().listen(_onUsbEvent);
    homeViewModel.setCallback(onCommandInvoke);
  }

  @override
  void dispose() {
    _betterPlayerController?.dispose();
    _timerTimeShowing.cancel();
    _subscription?.cancel();
    _subscription = null;

    checkAlive = false;
    usbPaths.clear();
    campSchedulesNew.clear();
    _setCampaignError.clear();

    homeViewModel.setCallback(null);

    super.dispose();
  }

  toggleDrawer() {
    isDrawerOpen = !isDrawerOpen;
    notifyListeners();
  }

  void onCommandInvoke(String command) {
    if (command == AppString.pauseVideo) {
      pauseVideo = !pauseVideo;
      homeViewModel.pauseVideo = pauseVideo;

      if (pauseVideo) {
        _betterPlayerController?.pause();
      } else {
        _betterPlayerController?.play();
      }
    } else if (command == AppString.stopVideo) {
      popPage();
    }
  }

  void popPage() {
    checkAlive = false;
    homeViewModel.notifyListeners();
    if (AppSP.get(AppSPKey.turnOffPJ) == 'true') {
      _dio.get(offProjector);
    }

    homeViewModel.playVideo = false;
    Navigator.pop(context);
  }

  void getCampSchedule() {
    String? lstCampScheduleString = AppSP.get(AppSPKey.lstCampSchedule);
    checkPacket = AppString.checkPacket;

    if (lstCampScheduleString != null &&
        lstCampScheduleString != '' &&
        checkPacket != null) {
      List<dynamic> lstCampScheduleJson = jsonDecode(lstCampScheduleString);
      campSchedulesNew =
          lstCampScheduleJson.map((e) => CampSchedule.fromJson(e)).toList();
      notifyListeners();
    }
  }

  void checkNumberOfPages(BuildContext context) {
    final observer = Navigator.of(context).widget.observers.firstWhere(
          (o) => o is CustomNavigatorObserver,
        ) as CustomNavigatorObserver;

    routerStackLength = observer.routeStack.length;
  }

  Future<void> _onUsbEvent(dynamic event) async {
    if (event == 'USB_DISCONNECTED') {
      _betterPlayerController?.dispose();
      checkDisconnectUSB = true;
    } else if (event == 'USB_CONNECTED') {
      checkDisconnectUSB = false;
      await _getUsbPath();
    }
  }

  void _updateTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final formattedTime = DateFormat('HH:mm:ss').format(now);
    _formattedTime = formattedTime;
    notifyListeners();
  }

  Future<void> _getUsbPath() async {
    usbPaths = await UsbService().getUsbPath();
    notifyListeners();
  }

  bool _isImage(String path) {
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif');
  }

  DateTime stringToDateTime(String time) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final second = int.parse(parts[2]);
    return DateTime(now.year, now.month, now.day, hour, minute, second)
        .toUtc()
        .add(const Duration(hours: 7));
  }

  Future<void> _loadNextMedia(List<CampSchedule> campSchedules,
      {int timeStart = 0}) async {
    if (!checkAlive || !context.mounted) return;
    _betterPlayerController?.dispose();
    isDisposeVideoPlayer = true;
    notifyListeners();

    image = null;
    if (currentIndex < campSchedules.length) {
      CampSchedule currentCampSchedule = campSchedules[currentIndex];
      DateTime fromTime = stringToDateTime(currentCampSchedule.fromTime);
      DateTime toTime = stringToDateTime(currentCampSchedule.toTime);
      DateTime now = DateTime.now().toUtc().add(const Duration(hours: 7));

      if (fromTime.isBefore(now) &&
          toTime.isAfter(now) &&
          currentCampSchedule.status == '1') {
        _waitTime = int.parse(currentCampSchedule.videoDuration);
        try {
          await _getUsbPath();

          if (checkShowingImage(currentCampSchedule)) {
            checkImage = true;

            if (usbPaths.isNotEmpty) {
              String nameImageSave =
                  currentCampSchedule.urlYoutube.split('/').last;
              String savePath = '${usbPaths.first}/Images/$nameImageSave';
              Directory imageDir = Directory('${usbPaths.first}/Images');

              if (!imageDir.existsSync()) {
                imageDir.createSync(recursive: true);
              }

              if (currentCampSchedule.videoType == 'url') {
                if (!File(savePath).existsSync()) {
                  bool isErrorInList = _setCampaignError
                      .contains(currentCampSchedule.campaignId);

                  if (!isErrorInList &&
                      await isImageUrlValid(currentCampSchedule.urlYoutube)) {
                    VideoDownloader.startDownload(
                        currentCampSchedule.urlYoutube,
                        savePath,
                        (progress) {});
                  } else {
                    if (!isErrorInList) {
                      _setCampaignError.add(currentCampSchedule.campaignId);
                    }
                    notifyListeners();
                    _loadNextMediaInList(campSchedules);
                    return;
                  }
                } else {
                  image = File(savePath);
                }
              } else if (File(
                      '${usbPaths.first}/Images/${currentCampSchedule.urlUsb}')
                  .existsSync()) {
                image = File(
                    '${usbPaths.first}/Images/${currentCampSchedule.urlUsb}');
              } else {
                _loadNextMediaInList(campSchedules);
                return;
              }
            } else {
              bool isErrorInList =
                  _setCampaignError.contains(currentCampSchedule.campaignId);
              if (isErrorInList ||
                  !(await isImageUrlValid(currentCampSchedule.urlYoutube))) {
                if (!isErrorInList) {
                  _setCampaignError.add(currentCampSchedule.campaignId);
                }
                notifyListeners();
                _loadNextMediaInList(campSchedules);
                return;
              }
            }

            notifyListeners();
            var counter = _waitTime;
            Timer.periodic(const Duration(seconds: 1), (timer) {
              counter -= pauseVideo ? 0 : 1;

              if (checkDisconnectUSB == true) {
                timer.cancel();
                checkDisconnectUSB = null;
                _loadNextMedia(campSchedules);
              } else if (counter <= 0 || !context.mounted) {
                timer.cancel();
                checkDisconnectUSB = null;
                _onMediaFinished(campSchedules);
              }
            });
          } else {
            checkImage = false;

            if (usbPaths.isEmpty) {
              bool isErrorInList =
                  _setCampaignError.contains(currentCampSchedule.campaignId);

              if (!isErrorInList &&
                  await isVideoUrlValid(currentCampSchedule.urlYoutube)) {
                // _betterPlayerController = VideoPlayerController.networkUrl(
                //     Uri.parse(currentCampSchedule.urlYoutube));
                await _setupVideo(currentCampSchedule.urlYoutube);
              } else {
                if (!isErrorInList) {
                  _setCampaignError.add(currentCampSchedule.campaignId);
                }
                _loadNextMediaInList(campSchedules);
                return;
              }
            } else {
              String nameVideoSave =
                  currentCampSchedule.urlYoutube.split('/').last;
              String savePath = '${usbPaths.first}/Videos/$nameVideoSave';
              Directory videoDir = Directory('${usbPaths.first}/Videos');

              if (currentCampSchedule.videoType == 'url') {
                if (!videoDir.existsSync()) {
                  videoDir.createSync(recursive: true);
                }

                if (!File(savePath).existsSync()) {
                  VideoDownloader.startDownload(
                      currentCampSchedule.urlYoutube, savePath, (progress) {});
                }

                if (!File(savePath).existsSync()) {
                  bool isErrorInList = _setCampaignError
                      .contains(currentCampSchedule.campaignId);

                  if (!isErrorInList &&
                      await isVideoUrlValid(currentCampSchedule.urlYoutube)) {
                    // _betterPlayerController = VideoPlayerController.networkUrl(
                    //     Uri.parse(currentCampSchedule.urlYoutube));
                    await _setupVideo(currentCampSchedule.urlYoutube);
                  } else {
                    if (!isErrorInList) {
                      _setCampaignError.add(currentCampSchedule.campaignId);
                    }
                    _loadNextMediaInList(campSchedules);
                    return;
                  }
                } else {
                  // _betterPlayerController =
                  //     VideoPlayerController.file(File(savePath));
                  await _setupVideo(savePath, inInternet: false);
                }
              } else {
                String usbPathh =
                    '${usbPaths.first}/Videos/${currentCampSchedule.urlUsb}';

                if (File(usbPathh).existsSync()) {
                  // _betterPlayerController =
                  //     VideoPlayerController.file(File(usbPathh));
                  await _setupVideo(usbPathh, inInternet: false);
                } else {
                  _loadNextMediaInList(campSchedules);
                  return;
                }
              }
            }
            // await _betterPlayerController!.initialize();
            // _betterPlayerController!.setLooping(true);
            _betterPlayerController!.play();
            isDisposeVideoPlayer = false;

            if (timeStart > 0) {
              _betterPlayerController!.seekTo(Duration(seconds: timeStart));
            }

            notifyListeners();
            var counter = _waitTime - timeStart;
            Timer.periodic(const Duration(seconds: 1), (timer) {
              counter -= pauseVideo ? 0 : 1;

              if (checkDisconnectUSB == true) {
                timer.cancel();
                checkDisconnectUSB = null;
                _loadNextMedia(campSchedules, timeStart: _waitTime - counter);
              } else if (counter <= 0 || !context.mounted) {
                timer.cancel();
                checkDisconnectUSB = null;
                _onMediaFinished(campSchedules);
              }
            });
          }
        } catch (e) {
          _loadNextMediaInList(campSchedules);
        }
      } else {
        if (!_setCampaignError.contains(currentCampSchedule.campaignId)) {
          _setCampaignError.add(currentCampSchedule.campaignId);
        }
        _loadNextMediaInList(campSchedules);
      }
    }
  }

  Future<void> _setupVideo(String url, {bool inInternet = true}) async {
    BetterPlayerConfiguration betterPlayerConfiguration =
        const BetterPlayerConfiguration(
      autoPlay: true,
      looping: true,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        showControls: false,
      ),
    );

    BetterPlayerDataSource betterPlayerDataSource = BetterPlayerDataSource(
      inInternet
          ? BetterPlayerDataSourceType.network
          : BetterPlayerDataSourceType.file,
      url,
    );

    // Tạo BetterPlayerController
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
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
  }

  Future<void> _loadNextMediaInList(List<CampSchedule> campSchedules) async {
    bool isAllInSet = campSchedules
        .map((e) => e.campaignId)
        .every((item) => _setCampaignError.contains(item));

    if (isAllInSet) {
      isPlaying = false;
      notifyListeners();
    } else {
      currentIndex++;
      if (currentIndex >= campSchedules.length) {
        currentIndex = 0;
      }

      checkDisconnectUSB = null;
      _loadNextMedia(campSchedules);
    }
  }

  void _onMediaFinished(List<CampSchedule> campSchedules) {
    CampSchedule currentCampSchedule = campSchedules[currentIndex];
    CampRequest campRequest = CampRequest();

    campRequest.addCampaignRunProfile(currentCampSchedule);

    _loadNextMediaInList(campSchedules);
  }

  bool checkShowingImage(CampSchedule currentCampSchedule) {
    return (currentCampSchedule.videoType == 'url' &&
            _isImage(currentCampSchedule.urlYoutube)) ||
        (currentCampSchedule.videoType == 'usb' &&
            _isImage(currentCampSchedule.urlUsb));
  }
}
