import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stacked/stacked.dart';

import '../app/app_sp.dart';
import '../app/app_sp_key.dart';
import '../models/device/device_info_model.dart';
import '../models/user/user.dart';
import '../request/account/account.request.dart';
import '../services/device_service.dart';
import '../view/authentication/login.page.dart';
import '../view/home/home.page.dart';

class SplashViewModel extends BaseViewModel {
  bool checkLogin = false;
  String token = "";
  String userJson = "";
  DeviceInfoModel? deviceInfo;
  bool isLoading = true;
  Future<void> init(BuildContext context) async {
    token = AppSP.get(AppSPKey.token) ?? "";
    userJson = AppSP.get(AppSPKey.user_info) ?? '';
    _requestPermissions(context);
  }

  Future<void> _requestPermissions(BuildContext context) async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      await _checkLogin();
      _navigateToNextPage(context);
    } else {
      // Quyền không được cấp
      print('Quyền truy cập bộ nhớ không được cấp');
    }
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
      }
    }
  }

  void _navigateToNextPage(BuildContext context) {
    Future.wait([
      Future.delayed(const Duration(seconds: 1)),
      _checkLogin(),
    ]).then((_) {
      if (checkLogin) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (router) => false);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (router) => false);
      }
    });
  }
}
