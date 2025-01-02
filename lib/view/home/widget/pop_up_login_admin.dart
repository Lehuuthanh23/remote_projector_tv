import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../app/app_sp.dart';
import '../../../app/app_sp_key.dart';
import '../../../view_models/home.vm.dart';

class PopUpLoginAdmin extends StatelessWidget {
  const PopUpLoginAdmin({super.key, required this.homeVM});
  final HomeViewModel homeVM;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
        disposeViewModel: false,
        viewModelBuilder: () => homeVM,
        builder: (context, viewModel, child) {
          return AlertDialog(
            title: const Text("Nhập tài khoản admin"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: viewModel.usernameAdminController,
                  decoration: const InputDecoration(
                    labelText: "Tài khoản",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: viewModel.passwordAdminController,
                  decoration: const InputDecoration(
                    labelText: "Mật khẩu",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                Text(
                  viewModel.errorStringCheckAdmin,
                  style: const TextStyle(color: Colors.red),
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // Đóng dialog
                },
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                onPressed: () async {
                  bool checkAdmin = await viewModel.checkAdmin();
                  if (checkAdmin == false) {
                    viewModel.errorStringCheckAdmin =
                        "Tài khoản hoặc mật khẩu không đúng";
                    viewModel.notifyListeners();
                  } else if (checkAdmin == true) {
                    await viewModel.dpc.unlockApp();
                    viewModel.dpc.setAsLauncher(enable: false);
                    viewModel.errorStringCheckAdmin = "";
                    viewModel.usernameAdminController.clear();
                    viewModel.passwordAdminController.clear();
                    viewModel.notifyListeners();
                    viewModel.kioskMode = false;
                    AppSP.set(AppSPKey.isKioskMode, viewModel.kioskMode);
                    Navigator.of(context).pop(); // Đóng dialog
                  }
                },
                child: const Text("Xác thực"),
              ),
            ],
          );
        });
  }
}
