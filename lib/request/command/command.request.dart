import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';

import '../../constants/api.dart';

class CommandRequest {
  final Dio _dio = Dio();

  static const String projectId = 'remote-projector-fc831';
  static const String fcmUri =
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
  static const String messagingScope =
      'https://www.googleapis.com/auth/firebase.messaging';

  AccessCredentials? _credentials;

  Future<void> replyCommand(String commandId, String contentReply) async {
    try {
      FormData formData = FormData.fromMap({
        'return_value': contentReply,
      });

      await _dio.post(
        '${Api.hostApi}${Api.replyCommand}/$commandId',
        data: formData,
      );
    } catch (_) {}
  }

  Future<bool> checkFirebase(String? token) async {
    try {
      Map<String, dynamic> jsonData = {
        'message': {
          'token': token,
          'data': {'cmd_id': '', 'cmd_code': ''}
        }
      };
      Map<String, String> headers = await _buildHeaders();
      var response = await _dio.post(
        fcmUri,
        options: Options(headers: headers),
        data: jsonData,
      );

      return response.statusCode == 200;
    } catch (_) {}

    return false;
  }

  /// Builds default header
  Future<Map<String, String>> _buildHeaders() async {
    if (_credentials == null) {
      await _autoRefreshCredentialsInitialize();
    }
    String? token = _credentials?.accessToken.data;
    Map<String, String> headers = {};
    headers["Authorization"] = 'Bearer $token';
    headers["Content-Type"] = 'application/json';
    return headers;
  }

  Future<void> _autoRefreshCredentialsInitialize() async {
    String source = await rootBundle
        .loadString('assets/remote-projector-fc831-5abcdfd47961.json');
    final serviceAccount = jsonDecode(source);
    var accountCredentials = ServiceAccountCredentials.fromJson(serviceAccount);

    try {
      AutoRefreshingAuthClient autoRefreshingAuthClient =
          await clientViaServiceAccount(
        accountCredentials,
        [messagingScope],
      );

      /// initialization
      _credentials = autoRefreshingAuthClient.credentials;

      autoRefreshingAuthClient.credentialUpdates.listen((credentials) {
        _credentials = credentials;
      });
    } catch (_) {}
  }
}
