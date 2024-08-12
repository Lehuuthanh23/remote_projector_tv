import 'package:flutter/material.dart';
import 'package:play_box/app/app_sp.dart';
import 'package:play_box/app/app_sp_key.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../app/app.locator.dart';
import '../app/app.router.dart';
import '../app/convert_md5.dart';
import '../models/user/authentication/request/login_request_model.dart';
import '../models/user/user.dart';
import '../request/account/account.request.dart';
import '../request/authentication/authentication.request.dart';
import '../services/google_sigin_api.service.dart';
import '../view/home/home.page.dart';
import '../widget/pop_up.dart';

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
  final _navigationService = appLocator<NavigationService>();
  final AuthenticationRequest _authenticationRequest = AuthenticationRequest();

  String? errorMessage;

  // @override
  // void dispose() {
  //   emailController.dispose();
  //   passwordController.dispose();
  //   emailFocusNode.dispose();
  //   passwordFocusNode.dispose();
  //   loginButtonFocusNode.dispose();
  //   exitButtonFocusNode.dispose();

  //   super.dispose();
  // }

  Future<void> handleLogin() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text;
    final password = convertToMD5(passwordController.text);

    final user = LoginRequestModel(email: email, password: password);
    final error = await request.login(user);

    if (error != null) {
      errorMessage = error;
    } else if (context.mounted) {
      AppSP.set(AppSPKey.loginWith, 'email');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    }
    notifyListeners();
  }

  Future signInWithGoogle() async {
    final user = await GoogleSignInService.login();
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Sign in failed')));
      }
    } else {
      AccountRequest accountRequest = AccountRequest();
      User? userModel = await accountRequest.getCustomerByEmail(user.email);
      if (userModel != null) {
        final userLogin = LoginRequestModel(email: user.email, password: '');
        final error = await _authenticationRequest.login(userLogin);
        if (error != null) {
          errorMessage = error;
          await GoogleSignInService.logout();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMessage ?? 'Sign in failed')));
          }
        } else if (context.mounted) {
          await AppSP.set(AppSPKey.loginWith, 'google');
          GoogleSignInService.initialize();
          _navigationService.clearStackAndShow(Routes.homePage);
        }
      } else if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) {
            Future.delayed(const Duration(seconds: 3), () {
              GoogleSignInService.logout();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            });
            return PopUpWidget(
              icon: Image.asset("assets/images/ic_error.png"),
              title: 'Tài khoản chưa được tạo',
              leftText: 'Xác nhận',
              onLeftTap: () async {
                GoogleSignInService.logout();
                Navigator.of(context).pop();
              },
            );
          },
        );
      }
    }
  }
}
