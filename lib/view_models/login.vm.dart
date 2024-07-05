import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../app/convert_md5.dart';
import '../models/user/authentication/request/login_request_model.dart';
import '../request/authentication/authentication.request.dart';
import '../view/home/home.page.dart';

class LoginViewModel extends BaseViewModel {
  LoginViewModel({required this.context});

  final BuildContext context;

  AuthenticationRequest request = AuthenticationRequest();

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  FocusNode loginButtonFocusNode = FocusNode();
  FocusNode exitButtonFocusNode = FocusNode();

  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    loginButtonFocusNode.dispose();
    exitButtonFocusNode.dispose();

    super.dispose();
  }

  Future<void> handleLogin() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text;
    final password = convertToMD5(passwordController.text);

    final user = LoginRequestModel(email: email, password: password);
    final error = await request.login(context, user);

    if (error != null) {
      errorMessage = error;
    } else if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    }
    notifyListeners();
  }
}
