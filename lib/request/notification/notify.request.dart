import 'dart:convert';

import 'package:dio/dio.dart';

import '../../app/app_sp.dart';
import '../../app/app_sp_key.dart';
import '../../app/app_utils.dart';
import '../../constants/api.dart';
import '../../models/device/device_model.dart';
import '../../models/notification/notify_model.dart';
import '../../models/user/user.dart';

class NotifyRequest {
  final Dio dio = Dio();
  addNotify(Notify notify) async {
    print('Vào thêm thông báo');
    User currentUser = User.fromJson(jsonDecode(AppSP.get(AppSPKey.user_info)));
    final formDataNotify = FormData.fromMap({
      'customer_id': currentUser.customerId,
      'title': notify.title,
      'descript': notify.descript,
      'detail': notify.detail,
      'picture': notify.picture,
    });
    final respone = await dio.post(
      AppUtils.createUrl(Api.insertNotify),
      data: formDataNotify,
      options: AppUtils.createOptionsNoCookie(),
    );
    print('Thêm thông báo: ${respone.data}');
  }
}
