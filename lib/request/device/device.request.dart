import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:play_box/models/device/device_model.dart';

import '../../app/app_utils.dart';
import '../../constants/api.dart';
import '../../models/device/device_info_model.dart';
import '../../models/user/user.dart';

class DeviceRequest {
  final Dio dio = Dio();
  Future<bool> connectDevice(
      Device device, DeviceInfoModel deviceInfo, User currentUser) async {
    bool checkConnect = false;
    final formData = FormData.fromMap({
      'computer_name': deviceInfo.model,
      'seri_computer': deviceInfo.androidId,
      'status': '1',
      'provinces': '',
      'district': '',
      'wards': '',
      'center_id': '5',
      'location': '',
      'customer_id': currentUser.customerId,
      'type': 'chia sẻ',
      'id_dir': '',
      'time_end': ''
    });
    try {
      final response = await dio.post(
        AppUtils.createUrl(Api.createDevice),
        data: formData,
        options: AppUtils.createOptionsNoCookie(),
      );
      print('Body thêm device: ${response.data}');
      final responseData = jsonDecode(response.data);
      if(responseData["status"] == 1){
        checkConnect = true;
        
      }
      else{

      }
    } catch (e) {
      print('Lỗi: $e');
    }
    return checkConnect;
  }
}
