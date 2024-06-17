import 'dart:convert';

import 'package:dio/dio.dart';

import '../../app/app_sp.dart';
import '../../app/app_sp_key.dart';
import '../../app/app_utils.dart';
import '../../constants/api.dart';
import '../../models/user/get_user_response_model.dart';
import '../../models/user/user.dart';

class AccountRequest {
  final Dio dio = Dio();
  Future<User?> getCustomer() async {
    try {
      var storedUserInfo = await AppSP.retrieveItem(AppSPKey.user_info);
      if (storedUserInfo != null) {
        final User userData = User.fromJson(storedUserInfo);

        final response = await dio.get(
          '${Api.hostApi}${Api.getCustomer}/${userData.customerId}',
        );
        final responseData = jsonDecode(response.data);
        print('responseData: $responseData');

        UserResponseModel customerResponse =
            UserResponseModel.fromJson(responseData);
        if (customerResponse.userList.isNotEmpty) {
          var updatedUser = customerResponse.userList.first;
          updatedUser.customerId = userData.customerId;
          return updatedUser;
        } else {
          // Handle case where no user information is returned from the API
          print('Không có dữ liệu user từ API');
          return userData; // Return original stored user data
        }
      } else {
        print('Không có dữ liệu user từ SharedPreferences');
        return null;
      }
    } catch (e) {
      print('Error fetching customer: $e');
      return null;
    }
  }

  Future<User?> getCustomerById(String id) async {
    final response = await dio.get(
      '${Api.hostApi}${Api.getCustomer}/$id',
    );
    final responseData = jsonDecode(response.data);
    UserResponseModel customerResponse =
        UserResponseModel.fromJson(responseData);
    if (customerResponse.userList.isNotEmpty) {
      User updatedUser = customerResponse.userList.first;
      updatedUser.customerId = id;
      return updatedUser;
    } else {
      // Handle case where no user information is returned from the API
      print('Không có dữ liệu user từ API');
      return null;
    }
  }

  Future<User?> getCustomerByEmail(String email) async {
    final response = await dio.get(
      '${Api.hostApi}${Api.getCustomerByEmail}/$email',
    );
    final responseData = jsonDecode(response.data);
    print('Body lấy customer: ${responseData.toString()}');
    UserResponseModel customerResponse =
        UserResponseModel.fromJson(responseData);
    if (customerResponse.userList.isNotEmpty) {
      User updatedUser = customerResponse.userList.first;
      updatedUser.email = email;
      print('Đúng điều kiện: ${updatedUser.customerName}');
      return updatedUser;
    } else {
      // Handle case where no user information is returned from the API
      print('Không có dữ liệu user từ API');
      return null;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    bool checkChange = false;
    User user = User.fromJson(jsonDecode(AppSP.get(AppSPKey.user_info)));
    FormData formData = FormData.fromMap({
      "email": user.email,
      "password_odd": oldPassword,
      "password_new": newPassword,
    });
    final response = await dio.post(
      '${Api.hostApi}${Api.changePassword}',
      data: formData,
      options: AppUtils.createOptionsNoCookie(),
    );
    final responseData = jsonDecode(response.data);
    if (responseData['status'] == 1) {
      checkChange = true;
      user.password = newPassword;
      AppSP.set(AppSPKey.user_info, user.toJson());
      AppSP.set(AppSPKey.token, user.password);
    } else {
      print('Lỗi: ${responseData.toString()}');
    }
    return checkChange;
  }

  Future<bool> updateCustomer(User user) async {
    FormData formData = FormData.fromMap({
      "email": user.email,
      "customer_name": user.customerName,
      "date_of_birth": user.dateOfBirth,
      "address": user.address,
      "phone_number": user.phoneNumber,
      "sex": user.sex,
    });
    final response = await dio.post(
      '${Api.hostApi}${Api.updateCustomer}/${user.customerId}',
      data: formData,
      options: AppUtils.createOptionsNoCookie(),
    );
    final responseData = jsonDecode(response.data);

    return responseData['status'] == 1;
  }
}
