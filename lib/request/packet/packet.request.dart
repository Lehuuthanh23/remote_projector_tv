import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../app/app_sp.dart';
import '../../app/app_sp_key.dart';
import '../../constants/api.dart';
import '../../models/packet/packet_model.dart';
import '../../models/user/user.dart';

class PacketRequest {
  Dio dio = Dio();
  Future<List<PacketModel>> getPacketByCustomerId() async {
    List<PacketModel> packets = [];
    User currentUser = User.fromJson(jsonDecode(AppSP.get(AppSPKey.user_info)));
    final response = await dio.get(
        '${Api.hostApi}${Api.getPacketByCustomerId}/${currentUser.customerId}');
    final responseData = jsonDecode(response.data);
    List<dynamic> packetList = responseData['Packet_list'];
    if (packetList.isNotEmpty) {
      packets = packetList.map((e) => PacketModel.fromJson(e)).toList();
    }

    packets = packets.where((packet) {
      if (packet.deleted != 'y') {
        DateTime now = DateTime.now();
        DateTime validDate = DateTime.parse(
            packet.validDate.isEmptyOrNull ? now.toString() : packet.validDate!);
        DateTime expireDate = DateTime.parse(
            packet.expireDate.isEmptyOrNull ? now.toString() : packet.expireDate!);
        return validDate.isBefore(now) && expireDate.isAfter(now);
      } else {
        return false;
      }
    }).toList();
    return packets;
  }
}
