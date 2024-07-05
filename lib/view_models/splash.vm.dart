import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:play_box/view_models/home.vm.dart';
import 'package:stacked/stacked.dart';

import '../app/app_sp.dart';
import '../app/app_sp_key.dart';
import '../app/app_utils.dart';
import '../models/device/device_info_model.dart';
import '../models/user/user.dart';
import '../request/account/account.request.dart';
import '../view/authentication/login.page.dart';
import '../view/home/home.page.dart';

class SplashViewModel extends BaseViewModel {
  BuildContext context;

  SplashViewModel({required this.context});

  bool checkLogin = false;
  String token = "";
  String userJson = "";
  String? idCustomer = '';
  DeviceInfoModel? deviceInfo;
  bool isLoading = true;
  Dio dio = Dio();
  String proUN = '';
  String proPW = '';
  String projectorIP = '';

  Future<void> init(BuildContext context) async {
    token = AppSP.get(AppSPKey.token) ?? "";
    userJson = AppSP.get(AppSPKey.user_info) ?? '';
    proUN = AppSP.get(AppSPKey.proUN) ?? '';
    proPW = AppSP.get(AppSPKey.proPW) ?? '';
    projectorIP = AppSP.get(AppSPKey.projectorIP) ?? '';
    if (AppSP.get(AppSPKey.openPJOnStartup) == 'true') {
      print('Mở máy chiếu khi mới khởi động');
      String onProjector =
          "http://$proUN:$proPW@$projectorIP/cgi-bin/sd95.cgi?cm=0200a13d0103";
      dio.get(onProjector);
    }
    _navigateToNextPage(context);
  }

  Future<void> _checkLogin() async {
    if (token.isNotEmpty) {
      var user = jsonDecode(userJson);
      User userFromJson = User.fromJson(user);
      AccountRequest request = AccountRequest();
      User? currentUser =
          await request.getCustomerById(userFromJson.customerId!);
      if (currentUser != null && token == currentUser.customerToken) {
        checkLogin = true;
        idCustomer = currentUser.customerId;
      }
    }
  }

  void _navigateToNextPage(BuildContext context) {
    _checkLogin();
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => checkLogin
                    ? const HomePage()
                    : const LoginPage()),
                (router) => false);
      }
    });
  }
}
