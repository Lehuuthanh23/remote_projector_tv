import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../app/app_sp.dart';
import '../../app/app_sp_key.dart';
import '../../main.dart';
import '../../view_models/login.vm.dart';
import '../../widget/button_custom.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return ViewModelBuilder<LoginViewModel>.reactive(
      viewModelBuilder: () => LoginViewModel(context: context),
      onViewModelReady: (viewModel) {},
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFEB6E2C),
                    Color(0xFFFABD1D),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/ts_screen.png',
                        width: 100,
                        height: 100,
                      ),
                      'TS Screen'.text.bold.color(Colors.white).size(25).make(),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width < height ? 50 : width / 3,
                        ),
                        child: Form(
                          key: viewModel.formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextFormField(
                                autofocus: true,
                                focusNode: viewModel.emailFocusNode,
                                controller: viewModel.emailController,
                                decoration:
                                    const InputDecoration(labelText: 'Email'),
                                onFieldSubmitted: (_) {
                                  FocusScope.of(context).requestFocus(
                                      viewModel.passwordFocusNode);
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Xin hãy nhập email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16.0),
                              TextFormField(
                                onFieldSubmitted: (_) {
                                  FocusScope.of(context).requestFocus(
                                      viewModel.loginButtonFocusNode);
                                },
                                focusNode: viewModel.passwordFocusNode,
                                controller: viewModel.passwordController,
                                decoration: const InputDecoration(
                                    labelText: 'Mật khẩu'),
                                obscureText: viewModel.obscurePassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Xin hãy nhập mật khẩu';
                                  }
                                  return null;
                                },
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    checkColor: Colors.amber,
                                    activeColor: Colors.grey.shade800,
                                    value: !viewModel.obscurePassword,
                                    onChanged: (value) {
                                      viewModel.showPassword(value);
                                    },
                                  ),
                                  const Text(
                                    'Hiện mật khẩu',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              viewModel.errorMessage != null
                                  ? const SizedBox(height: 16.0)
                                  : const SizedBox(height: 16),
                              if (viewModel.errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Text(
                                    viewModel.errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ButtonCustom(
                                autofocus: false,
                                focusNode: viewModel.loginButtonFocusNode,
                                isSplashScreen: true,
                                onPressed: () => viewModel.handleLogin(),
                                title: "ĐĂNG NHẬP",
                                textSize: 20,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 10,
                                ),
                              ),
                              ButtonCustom(
                                autofocus: false,
                                height: 45,
                                title: '',
                                isSplashScreen: true,
                                onPressed: () async {
                                  await viewModel.signInWithGoogle();
                                },
                                customTitle: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(right: 10),
                                      child: Image(
                                          image: AssetImage(
                                              'assets/images/ic_google.png'),
                                          width: 25,
                                          height: 25),
                                    ),
                                    Text(
                                      "Đăng nhập với Google",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 10,
                                ),
                                textSize: 20,
                              ),
                              ButtonCustom(
                                autofocus: false,
                                focusNode: viewModel.exitButtonFocusNode,
                                isSplashScreen: true,
                                onPressed: () {
                                  SystemNavigator.pop();
                                },
                                title: "THOÁT",
                                textSize: 20,
                                color: Colors.black,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 10,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  FocusScope.of(context)
                                      .requestFocus(viewModel.emailFocusNode);
                                },
                                child: const Text(
                                  'Nhập lại email',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await dpc.unlockApp();
                                    await dpc.setAsLauncher(enable: true);
                                    print('Unlock App');

                                    final success = await dpc.startApp();
                                    if (success) {
                                      print("Settings opened successfully");
                                      AppSP.set(
                                          AppSPKey.isSettingsOpened, true);
                                      // isSettingsOpened = true;
                                    } else {
                                      print("Failed to open Settings");
                                    }
                                  } catch (e) {
                                    print("Error opening Settings: $e");
                                  }
                                },
                                child: const Text(
                                  'Cài đặt wifi',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                  ),
                                ),
                              ),
                              // TextButton(
                              //   onPressed: () async {
                              //     dpc.unlockApp();

                              //   },
                              //   child: const Text(
                              //     'Trở về home',
                              //     style: TextStyle(
                              //       color: Colors.white,
                              //       fontSize: 15,
                              //       decoration: TextDecoration.underline,
                              //       decorationColor: Colors.white,
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
