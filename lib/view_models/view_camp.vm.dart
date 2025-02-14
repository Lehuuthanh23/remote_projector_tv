import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:better_player/better_player.dart';
import 'package:dio/dio.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:play_box/request/device/device.request.dart';
import 'package:stacked/stacked.dart';

import '../app/app_sp.dart';
import '../app/app_sp_key.dart';
import '../app/app_string.dart';
import '../app/app_utils.dart';
import '../models/camp/camp_model.dart';
import '../models/camp/camp_schedule.dart';
import '../models/device/device_model.dart';
import '../models/notification/notify_model.dart';
import '../observer/navigator_observer.dart';
import '../request/camp/camp.request.dart';
import '../request/notification/notify.request.dart';
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
  List<CampSchedule> lstCampSchedule = [];
  bool isSync = false;

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
  DateTime? now;
  StreamSubscription? _subscription;
  FocusNode drawerFocus = FocusNode();
  List<CampModel> camps = [];
  final CampRequest _campRequest = CampRequest();
  final DeviceRequest _deviceRequest = DeviceRequest();
  double _totalProgress = 0.0; // Tiến độ tổng thể (0.0 - 1.0)
  double get totalProgress => _totalProgress;
  int _totalBytesToDownload = 0;
  int _totalBytesDownloaded = 0;

  String _currentTask = ''; // Mô tả công việc hiện tại
  String get currentTask => _currentTask;

  /// Đồng bộ hóa thư mục Videos cục bộ với danh sách URL video.
  Future<void> syncVideo() async {
    isSync = true;
    _totalProgress = 0;
    _totalBytesToDownload = 0;
    _totalBytesDownloaded = 0;
    _currentTask = 'Đang tính toán dung lượng khả dụng';
    notifyListeners();
    await getMyCamp();
    await getCampSchedule1();
    // Trích xuất các URL YouTube từ camps
    List<String> listUrlVideo =
        camps.map((camp) => camp.urlYoutube.toString()).toList();

    // Trích xuất tên video từ URL
    List<String> listVideoNames =
        listUrlVideo.map((url) => getVideoName(url)).toList();

    // Chuẩn bị thư mục Videos
    String savePath = await prepareVideosDirectory();

    // Lấy danh sách các tệp video hiện có trong thư mục
    Directory videosDirectory = Directory(savePath);
    List<FileSystemEntity> existingFiles =
        await videosDirectory.list().toList();

    // Tạo bản đồ các tệp hiện có theo tên cơ bản (không có phần mở rộng)
    Map<String, File> existingVideoMap = {
      for (var file in existingFiles)
        if (file is File) getVideoName(file.path): file,
    };

    List<Function> tasks = [];
    Map<String, int> listUrlAndSize = {};
    double? freeDiskSpaceMB = await DiskSpacePlus.getFreeDiskSpace;
    double remainingFreeSpaceMB = freeDiskSpaceMB ?? 0;
    List<String> listVideoDownload = [];
    List<String> listVideoNotDownload = [];
    List<String> listVideoDelete = [];

// Th Thêm công việc tải xuống các video thiếu và tính toán tổng dung lượng
    for (var url in listUrlVideo) {
      String videoName = getVideoName(url);
      if (!existingVideoMap.containsKey(videoName)) {
        // Lấy kích thước tệp
        int? fileSize = await getFileSizeWithDio(url);
        if (fileSize != null) {
          listUrlAndSize[videoName] = fileSize;
          double videoSizeMB = fileSize / (1024 * 1024);
          if (videoSizeMB <= remainingFreeSpaceMB) {
            _totalBytesToDownload += fileSize;
            remainingFreeSpaceMB -= videoSizeMB;
            listVideoDownload.add(videoName);
            tasks.add(() => startVideoDownload(url, savePath));
          } else {
            listVideoNotDownload.add(videoName);
            print('Không đủ dung lượng để tải video: $videoName');
          }
        }
      } else {
        // Kiểm tra nếu tệp đã tồn tại nhưng kích thước không khớp
        File existingFile = existingVideoMap[videoName]!;
        int existingFileSize = await existingFile.length();
        int? expectedFileSize = await getFileSizeWithDio(url);

        if (expectedFileSize != null && existingFileSize != expectedFileSize) {
          tasks.add(() => deleteVideo(existingFile)); // Thêm công việc xóa tệp
          listUrlAndSize[videoName] = expectedFileSize;
          double videoSizeMB = expectedFileSize / (1024 * 1024);
          if (videoSizeMB <= remainingFreeSpaceMB) {
            _totalBytesToDownload += expectedFileSize;
            remainingFreeSpaceMB -= videoSizeMB;
            listVideoDownload.add(videoName);
            tasks.add(() =>
                startVideoDownload(url, savePath)); // Thêm công việc tải lại
          } else {
            listVideoNotDownload.add(videoName);
            print('Không đủ dung lượng để tải lại video: $videoName');
          }
        }
      }
    }

// Thêm công việc xóa các video không còn trong danh sách
    for (var entry in existingVideoMap.entries) {
      if (!listVideoNames.contains(entry.key)) {
        if (!listVideoNotDownload.contains(entry.key)) {
          listVideoDelete.add(entry.key);
          tasks.add(() => deleteVideo(entry.value));
        }
      }
    }
    int totalTasks = tasks.length;
    if (totalTasks == 0) {
      _totalProgress = 1.0;
      isSync = false;
      notifyListeners();
      print('Đồng bộ hóa hoàn tất. Không có công việc nào cần thực hiện.');
      updateRomMemory();
      return;
    }

    // Thực hiện các công việc lần lượt và cập nhật tiến độ
    for (int i = 0; i < tasks.length; i++) {
      await tasks[i]();
      notifyListeners();
    }
    if (listVideoNotDownload.isNotEmpty) {
      double requiredDiskSpaceMB = 0;
      for (var video in listUrlAndSize.entries) {
        if (listVideoNotDownload.contains(video.key)) {
          requiredDiskSpaceMB += video.value / (1024 * 1024);
        }
      }
      freeDiskSpaceMB = await DiskSpacePlus.getFreeDiskSpace;
      Device currentDevice =
          Device.fromJson(jsonDecode(AppSP.get(AppSPKey.currentDevice)));
      Notify notify = Notify(
          title: 'Thiết bị ${currentDevice.computerName} thiếu bộ nhớ',
          descript: 'Không thể tải đồng bộ tất cả video',
          detail: '''
Không đủ dung lượng lưu trữ. Cần ${requiredDiskSpaceMB.toStringAsFixed(2)} MB nhưng chỉ có ${freeDiskSpaceMB?.toStringAsFixed(2)} MB khả dụng.
**Các video được chọn để tải xuống (${listVideoDownload.length}):**
        ${listVideoDownload.join(', ')}

**Các video không thể tải xuống do thiếu dung lượng (${listVideoNotDownload.length}):**
${listVideoNotDownload.isNotEmpty ? listVideoNotDownload.join(', ') : 'Không có'}
              ''',
          picture: '');
      await NotifyRequest().addNotify(notify);
    }
    isSync = false;
    _totalProgress = 1;
    _currentTask = 'Đồng bộ hóa hoàn tất';
    updateRomMemory();
    notifyListeners();
  }

  updateRomMemory() async {
    double? freeDiskSpaceMB = await DiskSpacePlus.getFreeDiskSpace;
    double? totalDiskSpaceMB = await DiskSpacePlus.getTotalDiskSpace;
    Device device =
        Device.fromJson(jsonDecode(AppSP.get(AppSPKey.currentDevice)));
    _deviceRequest.updateRomDevice(
        device.computerId,
        (totalDiskSpaceMB! * 1024 * 1024).toString(),
        ((totalDiskSpaceMB * 1024 * 1024) - (freeDiskSpaceMB! * 1024 * 1024))
            .toString());
  }

  /// Bắt đầu tải xuống video từ URL cho trước vào savePath.
  /// Bắt đầu tải xuống video từ URL cho trước vào savePath.
  Future<void> startVideoDownload(String url, String savePath) async {
    try {
      String videoName = getVideoName(url);
      String filePath = '$savePath/$videoName';

      // Kiểm tra xem tệp đã tồn tại chưa
      File file = File(filePath);
      if (await file.exists()) {
        print('Tệp "$videoName" đã tồn tại tại $savePath.');
        return;
      }

      print('Đang tải "$videoName"');

      // Biến để theo dõi số byte đã tải trong tệp hiện tại
      int previousReceived = 0;

      // Bắt đầu tải xuống sử dụng Dio
      Dio dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Tính phần trăm tải xuống của tệp hiện tại
            double progress = received / total;

            // Tính sự tăng lên so với lần callback trước
            int delta = received - previousReceived;
            previousReceived = received;

            // Cập nhật tổng số byte đã tải
            _totalBytesDownloaded += delta;

            // Cập nhật tiến độ tổng thể
            _totalProgress = _totalBytesDownloaded /
                _totalBytesToDownload.clamp(1, double.infinity);

            // Cập nhật mô tả công việc hiện tại
            _currentTask =
                'Đang tải "$videoName": ${(progress * 100).toStringAsFixed(0)}%';
            notifyListeners();
          }
        },
      );

      print('Tải xuống hoàn tất: "$videoName"');
    } catch (e) {
      print('Lỗi khi tải video từ $url: $e');
    }
  }

  /// Xóa video khỏi thư mục.
  Future<void> deleteVideo(File file) async {
    try {
      String videoName = getVideoName(file.path);
      if (file.existsSync()) {
        await file.delete();
        print('Đã xóa video: $videoName');
      } else {
        print('Đã xóa video trước đó: $videoName');
      }
    } catch (e) {
      print('Lỗi khi xóa tệp ${file.path}: $e');
    }
  }

  /// Lấy kích thước tệp từ URL sử dụng yêu cầu HEAD.
  Future<int?> getFileSizeWithDio(String url) async {
    try {
      Dio dio = Dio();

      // Gửi yêu cầu HEAD
      Response response = await dio.head(url);

      // Trích xuất Content-Length từ header
      if (response.headers.value('content-length') != null) {
        return int.tryParse(response.headers.value('content-length')!);
      } else {
        print('Không tìm thấy header Content-Length cho $url.');
        return null;
      }
    } catch (e) {
      print('Lỗi khi lấy kích thước tệp cho $url: $e');
      return null;
    }
  }

  /// Trích xuất tên video từ URL đầy đủ hoặc đường dẫn tệp.
  String getVideoName(String fullPath) {
    // Lấy phần cuối cùng sau '/'
    String fileName = fullPath.split('/').last;

    // Loại bỏ các tham số truy vấn nếu có
    if (fileName.contains('?')) {
      fileName = fileName.split('?').first;
    }

    // Loại bỏ phần mở rộng tệp nếu có
    String videoName = fileName;

    return videoName;
  }

  /// Lấy danh sách các camp liên quan đến khách hàng.
  Future<void> getMyCamp() async {
    try {
      camps = await _campRequest.getAllCampByIdCustomer();
    } catch (e) {
      print('Lỗi khi lấy danh sách camp: $e');
    }
  }

  Future<void> getCampSchedule1() async {
    lstCampSchedule = await _campRequest.getCampSchedule();
    List<Map<String, dynamic>> jsonList =
        lstCampSchedule.map((camp) => camp.toJson()).toList();
    String lstCampScheduleString = jsonEncode(jsonList);
    AppSP.set(AppSPKey.lstCampSchedule, lstCampScheduleString);
  }

  /// Chuẩn bị thư mục Videos trong bộ nhớ ngoài.
  Future<String> prepareVideosDirectory() async {
    try {
      // Lấy thư mục bộ nhớ ngoài
      Directory? externalStorage = await getExternalStorageDirectory();

      if (externalStorage != null) {
        // Định nghĩa đường dẫn tới Videos
        String videosPath = '${externalStorage.path}/Videos';
        Directory videosDirectory = Directory(videosPath);

        // Tạo thư mục nếu chưa tồn tại
        if (!await videosDirectory.exists()) {
          await videosDirectory.create(recursive: true);
          print('Đã tạo thư mục Videos tại $videosPath');
        } else {
          print('Thư mục Videos đã tồn tại tại $videosPath');
        }

        return videosDirectory.path;
      } else {
        throw Exception("Không thể truy cập bộ nhớ ngoài.");
      }
    } catch (e) {
      throw Exception("Lỗi khi chuẩn bị thư mục Videos: $e");
    }
  }

  Future<String> getVideosDirectoryPath() async {
    try {
      // Lấy thư mục bộ nhớ ngoài
      Directory? externalStorage = await getExternalStorageDirectory();

      if (externalStorage != null) {
        // Định nghĩa đường dẫn tới Videos
        String videosPath = '${externalStorage.path}/Videos';
        return videosPath;
      } else {
        throw Exception("Không thể truy cập bộ nhớ ngoài.");
      }
    } catch (e) {
      throw Exception("Lỗi khi lấy đường dẫn thư mục Videos: $e");
    }
  }

  Future<void> deleteVideosDirectory() async {
    try {
      // Lấy đường dẫn thư mục Videos
      String videosPath = await getVideosDirectoryPath();

      Directory videosDirectory = Directory(videosPath);

      // Kiểm tra xem thư mục có tồn tại hay không
      if (await videosDirectory.exists()) {
        // Xóa thư mục cùng với tất cả các tệp bên trong
        await videosDirectory.delete(recursive: true);
        print('Đã xóa thư mục Videos tại $videosPath');

        // Thông báo cho các listener (nếu cần)
        notifyListeners();
      } else {
        print('Thư mục Videos không tồn tại tại $videosPath');
      }
    } catch (e) {
      print('Lỗi khi xóa thư mục Videos: $e');
    }
  }

  /// Lấy danh sách tên các tệp video trong thư mục Videos.
  Future<List<String>> getVideoFileNames() async {
    try {
      // Lấy đường dẫn thư mục Videos
      String savePath = await prepareVideosDirectory();

      Directory videosDirectory = Directory(savePath);

      // Kiểm tra xem thư mục có tồn tại không
      if (!await videosDirectory.exists()) {
        print('Thư mục Videos không tồn tại tại $savePath');
        return [];
      }

      // Lấy danh sách các tệp trong thư mục Videos
      List<FileSystemEntity> files = await videosDirectory.list().toList();

      // Lọc chỉ các tệp và lấy tên tệp
      List<String> fileNames = files
          .whereType<File>()
          .map((file) => file.path.split('/').last)
          .toList();

      return fileNames;
    } catch (e) {
      print('Lỗi khi lấy danh sách tên tệp video: $e');
      return [];
    }
  }

  init() async {
    await syncVideo();
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
      // updateRomMemory();
      String? lstCampScheduleString = AppSP.get(AppSPKey.lstCampSchedule);
      List<dynamic> lstCampScheduleJson = jsonDecode(lstCampScheduleString!);
      DateTime nowUtc = DateTime.now().toUtc().add(const Duration(hours: 7));
      DateTime nowLocalButUnchanged = DateTime(
        nowUtc.year,
        nowUtc.month,
        nowUtc.day,
        nowUtc.hour,
        nowUtc.minute,
        nowUtc.second,
      );
      if (lstCampScheduleJson
          .map((e) => CampSchedule.fromJson(e))
          .where((camp) {
            DateTime fromTime = stringToDateTime(camp.fromTime);
            DateTime toTime = stringToDateTime(camp.toTime);
            return (fromTime.isBefore(nowLocalButUnchanged) ||
                    nowLocalButUnchanged == fromTime) &&
                toTime.isAfter(nowLocalButUnchanged) &&
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
    _betterPlayerController = null;
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
    now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final formattedTime = DateFormat('HH:mm:ss').format(now!);
    _formattedTime = formattedTime;
    notifyListeners();
  }

  Future<void> _getUsbPath() async {
    usbPaths = await UsbService().getUsbPath();
    Directory? externalStorage = await getExternalStorageDirectory();

    if (externalStorage != null) {
      usbPaths.insert(0, externalStorage.path);
    }
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
    return DateTime(now.year, now.month, now.day, hour, minute, second);
  }

  bool isTodayInDaysOfWeek(List<String> daysOfWeek) {
    // Lấy ngày hiện tại
    DateTime now = DateTime.now().toUtc().add(const Duration(hours: 7));

    // Định nghĩa các thứ trong tuần tương ứng
    Map<int, String> weekdayMap = {
      1: 'T2',
      2: 'T3',
      3: 'T4',
      4: 'T5',
      5: 'T6',
      6: 'T7',
      7: 'CN',
    };

    // Lấy thứ của ngày hiện tại
    String today = weekdayMap[now.weekday] ?? '';

    // Kiểm tra xem ngày hiện tại có trong danh sách hay không
    return daysOfWeek.contains(today);
  }

  Future<void> _loadNextMedia(List<CampSchedule> campSchedules,
      {int timeStart = 0}) async {
    if (!checkAlive || !context.mounted) return;
    if (_betterPlayerController != null) {
      _betterPlayerController!.clearCache();
      await _betterPlayerController!.pause();
      _betterPlayerController!.dispose();
      _betterPlayerController = null;
    }
    isDisposeVideoPlayer = true;
    notifyListeners();
    image = null;
    if (currentIndex < campSchedules.length) {
      CampSchedule currentCampSchedule = campSchedules[currentIndex];
      DateTime fromTime = stringToDateTime(currentCampSchedule.fromTime);
      DateTime toTime = stringToDateTime(currentCampSchedule.toTime);
      DateTime nowUtc = DateTime.now().toUtc().add(const Duration(hours: 7));
      DateTime nowLocalButUnchanged = DateTime(
        nowUtc.year,
        nowUtc.month,
        nowUtc.day,
        nowUtc.hour,
        nowUtc.minute,
        nowUtc.second,
      );
      List<String> daysOfWeek = currentCampSchedule.daysOfWeek.split(',');
      if ((fromTime.isBefore(nowLocalButUnchanged) ||
              nowLocalButUnchanged == fromTime) &&
          toTime.isAfter(nowLocalButUnchanged) &&
          currentCampSchedule.status == '1' &&
          isTodayInDaysOfWeek(daysOfWeek)) {
        _waitTime = int.parse(currentCampSchedule.videoDuration);
        try {
          await _getUsbPath();

          if (checkShowingImage(currentCampSchedule)) {
            checkImage = true;

            if (usbPaths.isNotEmpty) {
              String nameImageSave =
                  currentCampSchedule.urlYoutube.split('/').last;
              String savePath = '${usbPaths.first}/Videos/$nameImageSave';
              Directory imageDir = Directory('${usbPaths.first}/Videos');

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
                      '${usbPaths.first}/Videos/${currentCampSchedule.urlUsb}')
                  .existsSync()) {
                image = File(
                    '${usbPaths.first}/Videos/${currentCampSchedule.urlUsb}');
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
                  // VideoDownloader.startDownload(
                  //     currentCampSchedule.urlYoutube, savePath, (progress) {});
                }
                if (!File(savePath).existsSync()) {
                  bool isErrorInList = _setCampaignError
                      .contains(currentCampSchedule.campaignId);

                  if (!isErrorInList &&
                      await isVideoUrlValid(currentCampSchedule.urlYoutube)) {
                        print('Chạy trong mạng: ${currentCampSchedule.urlYoutube}');
                    await _setupVideo(currentCampSchedule.urlYoutube);
                  } else {
                    if (!isErrorInList) {
                      _setCampaignError.add(currentCampSchedule.campaignId);
                    }
                    _loadNextMediaInList(campSchedules);
                    return;
                  }
                } else {
                  print('Chạy trong bộ nhớ trong: $savePath');
                  await _setupVideo(savePath, inInternet: false);
                }
              } else {
                String usbPathh =
                    '${usbPaths.first}/Videos/${currentCampSchedule.urlUsb}';

                if (File(usbPathh).existsSync()) {
                  await _setupVideo(usbPathh, inInternet: false);
                } else {
                  _loadNextMediaInList(campSchedules);
                  return;
                }
              }
            }
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
        flagPlayCamp = false;
        _loadNextMediaInList(campSchedules);
      }
    }
  }

  Future<void> _setupVideo(String url, {bool inInternet = true}) async {
    if (_betterPlayerController != null) {
      _betterPlayerController!.clearCache();
      await _betterPlayerController!.pause();
      _betterPlayerController!.dispose();
      _betterPlayerController = null;
    }
    BetterPlayerConfiguration betterPlayerConfiguration =
        const BetterPlayerConfiguration(
      autoPlay: true,
      looping: false,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        showControls: false,
      ),
    );

    BetterPlayerDataSource betterPlayerDataSource = BetterPlayerDataSource(
      inInternet
          ? BetterPlayerDataSourceType.network
          : BetterPlayerDataSourceType.file,
      url,
      cacheConfiguration: const BetterPlayerCacheConfiguration(
        useCache: true,
        maxCacheSize: 100 * 1024 * 1024, // 100 MB
        maxCacheFileSize: 10 * 1024 * 1024, // 10 MB per file
      ),
    );

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
    bool isAllInSet = campSchedules.map((e) => e.campaignId).every((item) {
      return _setCampaignError.contains(item);
    });
    if (isAllInSet) {
      isPlaying = false;
      notifyListeners();
    } else {
      currentIndex++;
      if (currentIndex >= campSchedules.length) {
        currentIndex = 0;
      }
      checkDisconnectUSB = null;
      if (context.mounted) {
        _loadNextMedia(campSchedules);
      }
    }
  }

  void _onMediaFinished(List<CampSchedule> campSchedules) {
    CampSchedule currentCampSchedule = campSchedules[currentIndex];
    CampRequest campRequest = CampRequest();

    campRequest.addCampaignRunProfile(currentCampSchedule);

    _betterPlayerController?.clearCache();
    _betterPlayerController?.pause();
    _betterPlayerController?.dispose();
    _betterPlayerController = null;

    _loadNextMediaInList(campSchedules);
  }

  bool checkShowingImage(CampSchedule currentCampSchedule) {
    return (currentCampSchedule.videoType == 'url' &&
            _isImage(currentCampSchedule.urlYoutube)) ||
        (currentCampSchedule.videoType == 'usb' &&
            _isImage(currentCampSchedule.urlUsb));
  }
}
