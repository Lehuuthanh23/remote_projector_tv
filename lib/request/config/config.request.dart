import 'dart:convert';

import 'package:dio/dio.dart';

import '../../constants/api.dart';
import '../../models/config/config_model.dart';

class ConfigRequest {
  final Dio _dio = Dio();

  Future<ConfigModel?> getConfig() async {
    try {
      final response = await _dio.get(Api.configApi);

      final responseData = jsonDecode(response.data);
      ConfigModel config = ConfigModel.fromJson(responseData);

      return config;
    } catch(_) {}

    return null;
  }
}