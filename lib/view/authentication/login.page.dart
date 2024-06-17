import 'package:flutter/material.dart';
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
    return ViewModelBuilder<LoginViewModel>.reactive(
        disposeViewModel: false,
        viewModelBuilder: () => LoginViewModel(),
        onViewModelReady: (viewModel) {
          viewModel.viewContext = context;
        },
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 30,
                      ),
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
                            horizontal: MediaQuery.of(context).size.width / 3),
                        child: Form(
                          key: viewModel.formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextFormField(
                                controller: viewModel.emailController,
                                decoration:
                                    const InputDecoration(labelText: 'Email'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Xin hãy nhập email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16.0),
                              TextFormField(
                                controller: viewModel.passwordController,
                                decoration: const InputDecoration(
                                    labelText: 'Mật khẩu'),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Xin hãy nhập mật khẩu';
                                  }
                                  return null;
                                },
                              ),
                              viewModel.errorMessagee != null
                                  ? const SizedBox(height: 16.0)
                                  : const SizedBox(height: 16),
                              if (viewModel.errorMessagee != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Text(
                                    viewModel.errorMessagee!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ButtomCustom(
                                isSplashScreen: true,
                                onPressed: () => viewModel.login(),
                                title: "ĐĂNG NHẬP",
                                textSize: 20,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 10),
                              ),
                              ButtomCustom(
                                onPressed: () =>
                                    print('Nhấn thoát'), //viewModel.login(),
                                title: "THOÁT",
                                textSize: 20,
                                color: Colors.black,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 10),
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
          );
        });
  }
}
