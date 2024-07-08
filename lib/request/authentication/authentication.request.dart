import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:play_box/constants/api.dart';

import '../../app/app_sp.dart';
import '../../app/app_sp_key.dart';
import '../../app/app_utils.dart';
import '../../models/device/device_info_model.dart';
import '../../models/user/authentication/request/login_request_model.dart';
import '../../models/user/authentication/response/login_response_model.dart';
import '../../services/device.service.dart';

class AuthenticationRequest {
  final Dio dio = Dio();
  DeviceInfoService deviceInfoService = DeviceInfoService();
  String checkError = '';
  DeviceInfoModel? deviceInfo;
  Future<String?> login(BuildContext context, LoginRequestModel user) async {
    final formData = FormData.fromMap({
      'email': user.email.trim(),
      'password': user.password.trim(),
    });

    try {
      final response = await dio.post(
        AppUtils.createUrl(Api.login),
        data: formData,
        options: AppUtils.createOptionsNoCookie(),
      );
      final responseData = jsonDecode(response.data);
      // Deserialize response into LoginResponseModel
      final loginResponse = LoginResponseModel.fromJson(responseData);
      if (loginResponse.status == 1 && loginResponse.info.isNotEmpty) {
        await fetchDeviceInfo();
        //final responseCheck = await dio.
        if (await checkCustomerByDevice(
            deviceInfo!.androidId, loginResponse.info.first.customerId!)) {
          return 'Thiết bị đã có quyền sở hữu';
        } else if (context.mounted) {
          await onLoginSuccess(context, response, loginResponse);
        }
        return null; // Successful login, no error message
      } else {
        return loginResponse.msg ?? 'Đăng nhập lỗi'; // Return error message
      }
    } on DioException catch (e) {
      return 'Có lỗi xảy ra: ${e.message}';
    } catch (e) {
      return 'Có lỗi xảy ra. Vui lòng thử lại.';
    }
  }

  onLoginSuccess(BuildContext context, Response<dynamic> response,
      LoginResponseModel loginResponse) async {
    if (loginResponse.info.isNotEmpty) {
      Map<String, dynamic> userJson = loginResponse.info.first.toJson();

      await AppSP.set(AppSPKey.token, userJson['customer_token']);
      await AppSP.set(AppSPKey.user_info, jsonEncode(userJson));
    }
    String id = AppSP.get(AppSPKey.token);
    String userInfo = AppSP.get(AppSPKey.user_info);
  }

  Future<bool> checkCustomerByDevice(
      String computerID, String customerID) async {
    bool check = false;
    final response = await dio.get(
      AppUtils.createUrl('${Api.getCustomerByDevice}/$computerID'),
    );

    final responseData = jsonDecode(response.data);
    checkError = response.data;
    List<dynamic> listUserJson = responseData['list'];
    if (listUserJson.isEmpty) {
      check = false;
    } else {
      if (listUserJson.any((user) => user['customer_id'] == customerID)) {
        check = false;
      } else {
        check = true;
      }
    }
    return check;
  }

  Future<void> fetchDeviceInfo() async {
    deviceInfo = await deviceInfoService.getDeviceInfo();
  }
}
