import 'package:flutter/material.dart';
import 'package:play_box/view_models/home.vm.dart';
import 'package:stacked/stacked.dart';

import '../app/convert_md5.dart';
import '../models/user/authentication/request/login_request_model.dart';
import '../request/authentication/authentication.request.dart';
import '../view/home/home.page.dart';

class LoginViewModel extends BaseViewModel {
  final BuildContext viewContext;

  LoginViewModel({required this.viewContext});

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  AuthenticationRequest request = AuthenticationRequest();
  String? errorMessage;
  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  FocusNode loginButtonFocusNode = FocusNode();
  FocusNode exitButtonFocusNode = FocusNode();

  Future<void> login() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    print('Nhấn đăng nhập');
    final email = emailController.text;
    final password = convertToMD5(passwordController.text);

    final user = LoginRequestModel(email: email, password: password);
    final error = await request.login(viewContext, user);
    print('Làm xong đăng nhập');
    if (error != null) {
      errorMessage = error;
    } else if (viewContext.mounted) {
      Navigator.pushAndRemoveUntil(
        viewContext,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    }
    notifyListeners();
  }
}
