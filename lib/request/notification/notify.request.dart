import 'dart:convert';

import 'package:dio/dio.dart';

import '../../app/app_sp.dart';
import '../../app/app_sp_key.dart';
import '../../app/app_utils.dart';
import '../../constants/api.dart';
import '../../models/notification/notify_model.dart';
import '../../models/user/user.dart';

class NotifyRequest {
  final Dio _dio = Dio();

  Future<void> addNotify(Notify notify) async {
    User currentUser = User.fromJson(jsonDecode(AppSP.get(AppSPKey.userInfo)));
    final formDataNotify = FormData.fromMap({
      'customer_id': currentUser.customerId,
      'title': notify.title,
      'descript': notify.descript,
      'detail': notify.detail,
      'picture': notify.picture,
    });

    try {
      await _dio.post(
        AppUtils.createUrl(Api.insertNotify),
        data: formDataNotify,
        options: AppUtils.createOptionsNoCookie(),
      );
    } catch (_) {}
  }
}
