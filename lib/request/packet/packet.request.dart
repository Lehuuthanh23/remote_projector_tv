import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:play_box/app/app_sp.dart';
import 'package:play_box/app/app_sp_key.dart';
import 'package:play_box/constants/api.dart';
import 'package:play_box/models/packet/packet_model.dart';
import 'package:play_box/models/user/user.dart';

class PacketRequest {
  Dio dio = Dio();
  Future<List<PacketModel>> getPacketByCustomerId() async {
    List<PacketModel> packets = [];
    User currentUser = User.fromJson(jsonDecode(AppSP.get(AppSPKey.user_info)));
    final response = await dio.get(
        '${Api.hostApi}${Api.getPacketByCustomerId}/${currentUser.customerId}');
    print(
        '${Api.hostApi}${Api.getPacketByCustomerId}/${currentUser.customerId}');
    print('Body packet: ${response.data}');
    final responseData = jsonDecode(response.data);
    List<dynamic> packetList = responseData['Packet_list'];
    if (packetList.isNotEmpty) {
      packets = packetList.map((e) => PacketModel.fromJson(e)).toList();
    }

    packets = packets.where((packet) {
      if (packet.deleted != 'y') {
        DateTime now = DateTime.now();
        DateTime valid_date = DateTime.parse(
            packet.validDate! == '' ? now.toString() : packet.validDate!);
        DateTime expireDate = DateTime.parse(
            packet.expireDate! == '' ? now.toString() : packet.expireDate!);
        return valid_date.isBefore(now) && expireDate.isAfter(now);
      } else {
        return false;
      }
    }).toList();
    print('Số lượng gói cước: ${packets.length}');
    return packets;
  }
}
