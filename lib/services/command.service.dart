import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:play_box/app/app_string.dart';
import 'package:play_box/models/command/command_model.dart';

import '../constants/api.dart';
import '../models/device/device_model.dart';

class CommandService {
  late BuildContext context;
  CommandService(this.context);
  Future<void> getCommand(Device device) async {
    List<Command> lstCmd = [];
    final response = await Dio().get(
        '${Api.hostApi}${Api.getNewCommandsBySeriComputer}/${device.serialComputer}');
    print(
        'Đường dẫn: ${'${Api.hostApi}${Api.getNewCommandsBySeriComputer}/${device.serialComputer}'}');
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.data);
      List<dynamic> cmdList = responseData['cmd_list'];
      if (cmdList.isNotEmpty) {
        lstCmd = cmdList.map((e) => Command.fromJson(e)).toList();
      }
      lstCmd.sort((a, b) {
        if (a.isImme != b.isImme) {
          // Các giá trị có isImme = 1 lên trên cùng
          return int.parse(b.isImme!) - int.parse(a.isImme!);
        } else {
          // Nếu cả hai đều có isImme giống nhau thì sắp xếp theo secondWait từ bé đến lớn
          return int.parse(a.secondWait!) - int.parse(b.secondWait!);
        }
      });
      for (var i = 0; i < lstCmd.length; i++) {
        print('${lstCmd[i].cmdId}/${lstCmd[i].cmdCode}');
        switch (lstCmd[i].cmdCode) {
          case 'GET_TIMENOW':
            {
              await replyCommandGetTimeNow(lstCmd[i]);
              break;
            }
          case 'SET_TIMENOW':
            {
              await replyCommandSetTimeNow(lstCmd[i]);
              break;
            }
          case 'RESTART_APP':
            {
              await replyCommandRestartApp(lstCmd[i]);
              break;
            }
          case 'RESTART_DEVICE':
            {
              await replyCommandRestartDevice(lstCmd[i]);
              break;
            }

          default:
            {
              print('Unknown command: ${lstCmd[i].cmdCode}');
            }
        }
      }

      print('Số lượng cmd là: ${lstCmd.length}');
    } else {
      print('Failed to fetch data');
    }
  }

  Future<void> replyCommandGetTimeNow(Command command) async {
    FormData formData =
        FormData.fromMap({"return_value": DateTime.now().toString()});
    final response = await Dio().post(
      '${Api.hostApi}${Api.replyCommand}/${command.cmdId}',
      data: formData,
    );
    print('Body khi gửi reply: ${response.data}');
  }

  Future<void> replyCommandSetTimeNow(Command command) async {
    print('Vào setTimeNow');
  }

  Future<void> replyCommandRestartApp(Command command) async {
    print('Vào restartapp');
    Phoenix.rebirth(context);
  }

  Future<void> replyCommandRestartDevice(Command command) async {
    print('Vào restartdevice');
  }
}
