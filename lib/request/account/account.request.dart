import 'dart:convert';

import 'package:dio/dio.dart';

import '../../app/app_sp.dart';
import '../../app/app_sp_key.dart';
import '../../constants/api.dart';
import '../../models/user/get_user_response_model.dart';
import '../../models/user/user.dart';

class AccountRequest {
  final Dio _dio = Dio();

  Future<User?> getCustomer() async {
    try {
      var storedUserInfo = await AppSP.retrieveItem(AppSPKey.userInfo);
      if (storedUserInfo != null) {
        final User userData = User.fromJson(storedUserInfo);

        final response = await _dio.get(
          '${Api.hostApi}${Api.getCustomer}/${userData.customerId}',
        );

        final responseData = jsonDecode(response.data);
        UserResponseModel customerResponse =
            UserResponseModel.fromJson(responseData);

        if (customerResponse.userList.isNotEmpty) {
          var updatedUser = customerResponse.userList.first;
          updatedUser.customerId = userData.customerId;

          return updatedUser;
        } else {
          // Handle case where no user information is returned from the API
          return userData; // Return original stored user data
        }
      }
    } catch (_) {}

    return null;
  }

  Future<User?> getCustomerById(String id) async {
    try {
      final response = await _dio.get(
        '${Api.hostApi}${Api.getCustomer}/$id',
      );

      final responseData = jsonDecode(response.data);
      UserResponseModel customerResponse =
      UserResponseModel.fromJson(responseData);

      if (customerResponse.userList.isNotEmpty) {
        User updatedUser = customerResponse.userList.first;
        updatedUser.customerId = id;

        return updatedUser;
      }
    } catch (_) {}

    return null;
  }

  Future<User?> getCustomerByEmail(String email) async {
    try {
      final response = await _dio.get(
        '${Api.hostApi}${Api.getCustomerByEmail}/$email',
      );

      final responseData = jsonDecode(response.data);
      UserResponseModel customerResponse =
      UserResponseModel.fromJson(responseData);

      if (customerResponse.userList.isNotEmpty) {
        User updatedUser = customerResponse.userList.first;
        updatedUser.email = email;

        return updatedUser;
      }
    } catch (_) {}

    return null;
  }
}
