import '../../user.dart';

class LoginResponseModel {
  int status;
  String? msg;
  List<User> info;

  LoginResponseModel({
    required this.status,
    required this.msg,
    required this.info,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    List<User> infoObjs = [];

    if (json['info'] != 0 && json['status'] == 1) {
      var infoList = json['info'] as List;
      infoObjs = infoList.map((infoJson) => User.fromJson(infoJson)).toList();
    }

    return LoginResponseModel(
      status: json['status'],
      msg: json['msg'],
      info: infoObjs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'msg': msg,
      'info': info.map((info) => info.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'LoginResponse(status: $status, msg: $msg, info: $info)';
  }
}
