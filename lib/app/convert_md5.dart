import 'dart:convert';
import 'dart:core';

import 'package:crypto/crypto.dart';

import '../constants/api.dart';
import '../models/config/config_model.dart';
import 'app_sp.dart';
import 'app_sp_key.dart';
import 'app_utils.dart';

String convertToMD5(String input) {
  // Chuyển đổi chuỗi thành bytes
  var bytes = utf8.encode(input);

  // Mã hóa bytes thành MD5
  var digest = md5.convert(bytes);

  // Trả về chuỗi MD5 dưới dạng hex
  return digest.toString();
}

void saveConfig(ConfigModel? config) {
  if (config != null) {
    AppSP.set(AppSPKey.config, jsonEncode(config));
  } else {
    AppSP.set(AppSPKey.config, '');
    AppUtils.platformChannel.invokeMethod('clearUser');
  }
  AppUtils.platformChannel
      .invokeMethod('setHost', {AppSPKey.host: Api.hostApi});
}
