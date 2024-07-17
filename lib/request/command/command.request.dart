import 'package:dio/dio.dart';

import '../../constants/api.dart';

class CommandRequest {
  final Dio _dio = Dio();

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
}
