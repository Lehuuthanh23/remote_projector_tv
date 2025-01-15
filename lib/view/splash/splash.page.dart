import 'package:device_policy_controller/device_policy_controller.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../app/app_sp.dart';
import '../../app/app_sp_key.dart';
import '../../constants/app_color.dart';
import '../../view_models/splash.vm.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final dpc = DevicePolicyController.instance;
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SplashViewModel>.reactive(
      viewModelBuilder: () => SplashViewModel(context: context),
      onViewModelReady: (viewModel) async {
        await viewModel.init(context);
      },
      builder: (context, viewModel, child) {
        return Scaffold(
          body: Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColor.appBarStart,
                  AppColor.appBarEnd,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'TS Screen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  viewModel.errorString,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (viewModel.errorString != '')
                  TextButton(
                    onPressed: () async {
                      try {
                        await dpc.unlockApp();
                        await dpc.setAsLauncher(enable: true);
                        print('Unlock App');

                        final success = await dpc.startApp();
                        if (success) {
                          print("Settings opened successfully");
                          AppSP.set(AppSPKey.isSettingsOpened, true);
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
              ],
            ),
          ),
        );
      },
    );
  }
}
