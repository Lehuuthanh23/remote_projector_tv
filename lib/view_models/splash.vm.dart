import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:stacked/stacked.dart';

import '../app/app_sp.dart';
import '../app/app_sp_key.dart';
import '../app/app_utils.dart';
import '../app/convert_md5.dart';
import '../constants/api.dart';
import '../models/config/config_model.dart';
import '../models/device/device_info_model.dart';
import '../models/user/user.dart';
import '../request/account/account.request.dart';
import '../request/config/config.request.dart';
import '../services/google_sigin_api.service.dart';
import '../view/authentication/login.page.dart';
import '../view/home/home.page.dart';

class SplashViewModel extends BaseViewModel {
  SplashViewModel({required this.context});

  BuildContext context;

  final ConfigRequest _configRequest = ConfigRequest();
  Dio dio = Dio();

  DeviceInfoModel? deviceInfo;
  String token = "";
  String userJson = "";
  String proUN = '';
  String proPW = '';
  String projectorIP = '';
  bool checkLogin = false;
  bool isLoading = true;
  String errorString = '';
  bool checkConnect = false;

  Future<void> init(BuildContext context) async {
    token = AppSP.get(AppSPKey.token) ?? "";
    userJson = AppSP.get(AppSPKey.userInfo) ?? '';
    proUN = AppSP.get(AppSPKey.proUN) ?? '';
    proPW = AppSP.get(AppSPKey.proPW) ?? '';
    projectorIP = AppSP.get(AppSPKey.projectorIP) ?? '';
    if (AppSP.get(AppSPKey.openPJOnStartup) == 'true') {
      String onProjector =
          "http://$proUN:$proPW@$projectorIP/cgi-bin/sd95.cgi?cm=0200a13d0103";
      dio.get(onProjector);
    }

    _navigateToNextPage(context);
  }

  Future<void> _checkLogin() async {
    bool hasInternet = await InternetConnection().hasInternetAccess;

    if (hasInternet) {
      // Nếu đã có kết nối internet, thực hiện đăng nhập ngay lập tức
      await _attemptLogin();
      return;
    }

    // Nếu chưa có kết nối internet, thiết lập listener để đợi kết nối
    final Completer<void> completer = Completer<void>();

    StreamSubscription<InternetStatus>? listener;

    listener = InternetConnection()
        .onStatusChange
        .listen((InternetStatus status) async {
      if (status == InternetStatus.connected) {
        print('Có internet');
        checkConnect = true;
        errorString = '';
        await _attemptLogin();
        notifyListeners();
        completer
            .complete(); // Hoàn thành Completable khi kết nối được phục hồi
        await listener?.cancel(); // Hủy bỏ listener sau khi hoàn thành
      } else if (status == InternetStatus.disconnected) {
        print('Không có kết nối internet');
        errorString = 'Không có kết nối internet';
        checkConnect = false;
        notifyListeners();
      }
    });

    // Đợi cho đến khi completer được hoàn thành (khi kết nối internet được phục hồi)
    await completer.future;
  }

  _attemptLogin() async {
    ConfigModel? config;
    config = await _configRequest.getConfig();
    saveConfig(config);
    if (config != null) {
      Api.hostApi = config.apiServer ?? Api.hostApi;
    } else {
      clearUser();
    }
    String? loginWith = AppSP.get(AppSPKey.loginWith) ?? '';

    if (token.isNotEmpty) {
      if (loginWith == 'google') {
        checkLogin = await GoogleSignInService.signInSilently() != null;
        if (checkLogin) {
          GoogleSignInService.initialize();
        }
      } else {
        var user = jsonDecode(userJson);
        User userFromJson = User.fromJson(user);
        AccountRequest request = AccountRequest();
        User? currentUser =
            await request.getCustomerById(userFromJson.customerId!);

        if (currentUser != null && token == currentUser.customerToken) {
          checkLogin = true;
        } else {
          clearUser();
        }
      }
    }
  }

  void clearUser() {
    AppUtils.platformChannel.invokeMethod('clearUser');
  }

  Future<void> _navigateToNextPage(BuildContext context) async {
    await _checkLogin();
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) =>
                    checkLogin ? const HomePage() : const LoginPage()),
            (router) => false);
      }
    });
  }
}
