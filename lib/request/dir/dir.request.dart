import 'dart:convert';

import 'package:dio/dio.dart';

import '../../app/app_sp.dart';
import '../../app/app_sp_key.dart';
import '../../constants/api.dart';
import '../../models/dir/dir_model.dart';
import '../../models/user/user.dart';

class DirRequest {
  final Dio dio = Dio();

  Future<List<Dir>> getMyDir() async {
    String userInfo = AppSP.get(AppSPKey.userInfo);
    final userJson = jsonDecode(userInfo);
    User currentUser = User.fromJson(userJson);

    try {
      final response = await dio.get(
        '${Api.hostApi}${Api.getCustomerDir}/${currentUser.customerId}',
      );
      final responseData = jsonDecode(response.data);
      List<dynamic> list = responseData['Dir_list'];

      List<Dir> listDir = [];
      if (list.isNotEmpty) {
        listDir = list.map((e) => Dir.fromJson(e)).toList();
      }

      return listDir;
    } catch (_) {}

    return [];
  }

  Future<List<Dir>> getShareDir() async {
    String userInfo = AppSP.get(AppSPKey.userInfo);
    final userJson = jsonDecode(userInfo);
    User currentUser = User.fromJson(userJson);

    try {
      final response = await dio.get(
        '${Api.hostApi}${Api.getShareDir}/${currentUser.customerId}',
      );

      final responseData = jsonDecode(response.data);
      List<dynamic> dirList = responseData['Dir_list'];

      List<Dir> lstDir = [];
      if (dirList.isNotEmpty) {
        lstDir = dirList.map((e) => Dir.fromJson(e)).toList();
      }

      return lstDir;
    } catch (_) {}

    return [];
  }
}
