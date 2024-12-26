import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:play_box/app/convert_md5.dart';

import '../../app/app_sp.dart';
import '../../app/app_sp_key.dart';
import '../../app/app_utils.dart';
import '../../constants/api.dart';
import '../../models/device/device_info_model.dart';
import '../../models/user/authentication/request/login_request_model.dart';
import '../../models/user/authentication/response/login_response_model.dart';
import '../../services/device.service.dart';

class AuthenticationRequest {
  final Dio _dio = Dio();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  DeviceInfoModel? deviceInfo;

  Future<bool> checkLoginAdmin(String userName, String password) async {
    final formData = FormData.fromMap({
      'username': userName.trim(),
      'password': convertToMD5(password),
    });

    try {
      final response = await _dio.post(
        '${Api.hostApi}${Api.loginAdmin}',
        data: formData,
      );
      final responseData = jsonDecode(response.data);
      if (responseData['status'] == 1) {
        List<dynamic> listUser = responseData['accountList'];
        if (listUser.isNotEmpty) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> login(LoginRequestModel user) async {
    final formData = FormData.fromMap({
      'email': user.email.trim(),
      'password': user.password.trim(),
    });

    try {
      final response = await _dio.post(
        AppUtils.createUrl(Api.login),
        data: formData,
        options: AppUtils.createOptionsNoCookie(),
      );

      final responseData = jsonDecode(response.data);
      final loginResponse = LoginResponseModel.fromJson(responseData);

      if (loginResponse.status == 1 && loginResponse.info.isNotEmpty) {
        await fetchDeviceInfo();
        if (await checkCustomerByDevice(
          deviceInfo!.androidId,
          loginResponse.info.first.customerId!,
        )) {
          return 'Thiết bị đã có quyền sở hữu.';
        } else {
          await onLoginSuccess(response, loginResponse);
        }

        return null;
      } else {
        return loginResponse.msg ?? 'Tài khoản hoặc mật khẩu không chính xác.';
      }
    } catch (_) {
      return 'Đã có lỗi xảy ra. Vui lòng thử lại sau.';
    }
  }

  Future<void> onLoginSuccess(
      Response<dynamic> response, LoginResponseModel loginResponse) async {
    if (loginResponse.info.isNotEmpty) {
      Map<String, dynamic> userJson = loginResponse.info.first.toJson();

      await AppSP.set(AppSPKey.token, userJson['customer_token']);
      await AppSP.set(AppSPKey.userInfo, jsonEncode(userJson));
    }
  }

  Future<bool> checkCustomerByDevice(
      String computerID, String customerID) async {
    bool check = false;

    try {
      final response = await _dio.get(
        AppUtils.createUrl('${Api.getCustomerByDevice}/$computerID'),
      );

      final responseData = jsonDecode(response.data);
      List<dynamic> listUserJson = responseData['list'];

      if (listUserJson.isNotEmpty) {
        check = !listUserJson.any((user) => user['customer_id'] == customerID);
      }
    } catch (_) {}

    return check;
  }

  Future<void> fetchDeviceInfo() async {
    deviceInfo = await _deviceInfoService.getDeviceInfo();
  }
}
