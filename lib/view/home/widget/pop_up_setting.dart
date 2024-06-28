import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:play_box/app/app_sp.dart';
import 'package:play_box/app/app_sp_key.dart';
import 'package:play_box/app/app_utils.dart';
import '../../../view_models/home.vm.dart';
import '../../../widget/buttonCustom.dart';
import 'package:stacked/stacked.dart';

class PopupSettingScreen extends StatelessWidget {
  const PopupSettingScreen({Key? key, required this.homeVM}) : super(key: key);
  final HomeViewModel homeVM;

  @override
  Widget build(BuildContext context) {
    bool checkConnect = true;
    return ViewModelBuilder<HomeViewModel>.reactive(
        disposeViewModel: false,
        viewModelBuilder: () => homeVM,
        onViewModelReady: (viewModel) async {
          viewModel.viewContext = context;
          checkConnect = await AppUtils.checkConnect();
          viewModel.notifyListeners();
        },
        builder: (context, viewModel, child) {
          return Center(
            child: Container(
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(8.0),
                    alignment: Alignment.center,
                    child: const Text(
                      'CÀI ĐẶT',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: FocusTraversalGroup(
                          policy: WidgetOrderTraversalPolicy(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'THÔNG TIN CÁ NHÂN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      readOnly: true,
                                      enabled: false,
                                      decoration: InputDecoration(
                                        label: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Họ & tên',
                                              style: TextStyle(
                                                  color: Color(0xff797979),
                                                  fontSize: 15),
                                            ),
                                            Text(
                                              homeVM.currentUser.customerName!,
                                              style:
                                                  const TextStyle(fontSize: 20),
                                            ),
                                          ],
                                        ),
                                        prefixIcon: Image.asset(
                                            'assets/images/ic_profile.png'),
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      readOnly: true,
                                      enabled: false,
                                      decoration: InputDecoration(
                                        label: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Số điện thoại',
                                              style: TextStyle(
                                                  color: Color(0xff797979),
                                                  fontSize: 15),
                                            ),
                                            Text(
                                              homeVM.currentUser.phoneNumber!,
                                              style:
                                                  const TextStyle(fontSize: 20),
                                            ),
                                          ],
                                        ),
                                        prefixIcon: Image.asset(
                                            'assets/images/ic_phone_number.png'),
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'THÔNG TIN KẾT NỐI',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextFormField(
                                          enabled: false,
                                          decoration: InputDecoration(
                                            labelText: homeVM.deviceInfo!
                                                        .serialNumber ==
                                                    'unknown'
                                                ? 'ANDROID ID'
                                                : 'SERI NUMBER',
                                            hintText: '',
                                            enabled: false,
                                            border:
                                                const UnderlineInputBorder(),
                                          ),
                                          initialValue: homeVM.deviceInfo!
                                                      .serialNumber ==
                                                  'unknown'
                                              ? homeVM.deviceInfo!.androidId
                                              : homeVM.deviceInfo!.serialNumber,
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          decoration: const InputDecoration(
                                            labelText: 'Trạng thái',
                                            hintText: '',
                                            enabled: false,
                                            border: UnderlineInputBorder(),
                                          ),
                                          initialValue: 'Đang chạy',
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          decoration: const InputDecoration(
                                            labelText: 'Tên thiết bị',
                                            hintText: '',
                                            enabled: false,
                                            border: UnderlineInputBorder(),
                                          ),
                                          initialValue:
                                              homeVM.deviceInfo!.model,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFieldSetting(
                                                label: 'ProUN',
                                                controller: viewModel.proUN,
                                                enabled: (AppSP.get(AppSPKey
                                                                .proUN) ??
                                                            '') !=
                                                        ''
                                                    ? true
                                                    : true,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: TextFieldSetting(
                                                label: 'ProPW',
                                                controller: viewModel.proPW,
                                                enabled: (AppSP.get(AppSPKey
                                                                .proPW) ??
                                                            '') !=
                                                        ''
                                                    ? true
                                                    : true,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: TextFieldSetting(
                                                label: 'ProjectorIP',
                                                controller:
                                                    viewModel.projectorIP,
                                                enabled: (AppSP.get(AppSPKey
                                                                .projectorIP) ??
                                                            '') !=
                                                        ''
                                                    ? true
                                                    : true,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Checkbox(
                                              checkColor: Colors.amber,
                                              activeColor: Colors.transparent,
                                              focusNode: FocusNode(),
                                              value: homeVM.turnOnlPJ,
                                              onChanged: (bool? value) {
                                                homeVM.turnOnl();
                                              },
                                            ),
                                            const Text('Điều khiển mở PJ'),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Checkbox(
                                              checkColor: Colors.amber,
                                              activeColor: Colors.transparent,
                                              focusNode: FocusNode(),
                                              value: homeVM.turnOffPJ,
                                              onChanged: (bool? value) {
                                                homeVM.turnOff();
                                              },
                                            ),
                                            const Text('Điều khiển tắt PJ'),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Checkbox(
                                              checkColor: Colors.amber,
                                              activeColor: Colors.transparent,
                                              focusNode: FocusNode(),
                                              value: homeVM.openOnStartup,
                                              onChanged: (bool? value) {
                                                homeVM.openOnStart();
                                              },
                                            ),
                                            const Text('Mở khi khởi động'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ButtomCustom(
                        width: 150,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: const Color(0xffEB6E2C),
                        onPressed: () async {
                          checkConnect ? null : await homeVM.connectDevice();
                        },
                        title: checkConnect ? 'ĐÃ KẾT NỐI' : 'KẾT NỐI',
                        textSize: 15,
                      ),
                      ButtomCustom(
                        width: 150,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: Colors.black,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        title: 'THOÁT',
                        textSize: 15,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
  }
}

class TextFieldSetting extends StatelessWidget {
  const TextFieldSetting({
    super.key,
    required this.controller,
    required this.label,
    required this.enabled,
  });
  final TextEditingController controller;
  final String label;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: enabled ? FocusNode() : null,
      readOnly: !enabled,
      cursorColor: Colors.black,
      decoration: InputDecoration(
        labelText: label,
        hintText: '',
        enabled: enabled,
        labelStyle: const TextStyle(color: Colors.black),
        border: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black)),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black)),
      ),
      onChanged: (value) {
        controller.text = value;
      },
    );
  }
}
