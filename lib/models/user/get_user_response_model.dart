import 'user.dart';

class UserResponseModel {
  final int status;
  final String msg;
  final List<User> userList;

  UserResponseModel({
    required this.status,
    required this.msg,
    required this.userList,
  });

  factory UserResponseModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> userJsonList = json['userList'];
    List<User> users =
        userJsonList.map((userJson) => User.fromJson(userJson)).toList();

    return UserResponseModel(
      status: json['status'],
      msg: json['msg'],
      userList: users,
    );
  }
}
