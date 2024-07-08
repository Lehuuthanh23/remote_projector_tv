import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:stacked/stacked.dart';

import '../../view_models/login.vm.dart';
import '../../widget/buttonCustom.dart';

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
                        'assets/images/ic_projector.png',
                        width: 150,
                        height: 150,
                      ),
                      'REMOTE PROJECTOR'
                          .text
                          .bold
                          .color(Colors.white)
                          .size(25)
                          .make(),
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
                                focusNode: viewModel.emailFocusNode,
                                controller: viewModel.emailController,
                                decoration:
                                const InputDecoration(labelText: 'Email'),
                                onFieldSubmitted: (_) {
                                  FocusScope.of(context)
                                      .requestFocus(viewModel.passwordFocusNode);
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
                                decoration:
                                const InputDecoration(labelText: 'Mật khẩu'),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Xin hãy nhập mật khẩu';
                                  }
                                  return null;
                                },
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
                              ButtomCustom(
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
                              ButtomCustom(
                                focusNode: viewModel.exitButtonFocusNode,
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
