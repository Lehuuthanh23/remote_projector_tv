import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:play_box/app/convert_md5.dart';
import 'package:stacked/stacked.dart';

import '../app/app_sp.dart';
import '../app/app_sp_key.dart';
import '../app/app_utils.dart';
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
    ConfigModel? config = await _configRequest.getConfig();
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
