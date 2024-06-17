import 'package:flutter/material.dart';
import 'package:play_box/app/app_sp.dart';
import 'package:play_box/app/app_sp_key.dart';
import '../../../view_models/home.vm.dart';
import '../../../widget/buttonCustom.dart';
import 'package:stacked/stacked.dart';

class PopupSettingScreen extends StatelessWidget {
  const PopupSettingScreen({Key? key, required this.homeVM}) : super(key: key);
  final HomeViewModel homeVM;
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
        disposeViewModel: false,
        viewModelBuilder: () => homeVM,
        onViewModelReady: (viewModel) async {
          viewModel.viewContext = context;
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
                                    child: Focus(
                                      child: TextFormField(
                                        focusNode: FocusNode(),
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
                                                homeVM
                                                    .currentUser.customerName!,
                                                style: const TextStyle(
                                                    fontSize: 20),
                                              ),
                                            ],
                                          ),
                                          prefixIcon: Image.asset(
                                              'assets/images/ic_profile.png'),
                                          border: const OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Focus(
                                      child: TextFormField(
                                        readOnly: true,
                                        enabled: false,
                                        focusNode: FocusNode(),
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
                                                style: const TextStyle(
                                                    fontSize: 20),
                                              ),
                                            ],
                                          ),
                                          prefixIcon: Image.asset(
                                              'assets/images/ic_phone_number.png'),
                                          border: const OutlineInputBorder(),
                                        ),
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
                                        Focus(
                                          child: TextFormField(
                                            focusNode: FocusNode(),
                                            enabled: false,
                                            decoration: const InputDecoration(
                                              labelText: 'ANDROID ID',
                                              hintText: '',
                                              enabled: false,
                                              border: UnderlineInputBorder(),
                                            ),
                                            initialValue:
                                                homeVM.deviceInfo!.androidId,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Focus(
                                          child: TextFormField(
                                            focusNode: FocusNode(),
                                            decoration: const InputDecoration(
                                              labelText: 'Trạng thái',
                                              hintText: '',
                                              enabled: false,
                                              border: UnderlineInputBorder(),
                                            ),
                                            initialValue: 'Đã tắt',
                                          ),
                                        ),
                                        Focus(
                                          child: TextFormField(
                                            focusNode: FocusNode(),
                                            controller: viewModel.proUN,
                                            decoration: const InputDecoration(
                                              labelText: 'ProUN',
                                              hintText: '',
                                              border: UnderlineInputBorder(),
                                            ),
                                            onChanged: (value) {
                                              viewModel.proUN.text = value;
                                              AppSP.set(AppSPKey.proUN,
                                                  viewModel.proUN.text);
                                              viewModel.notifyListeners();
                                            },
                                          ),
                                        ),
                                        Focus(
                                          child: TextFormField(
                                            controller: viewModel.proPW,
                                            focusNode: FocusNode(),
                                            decoration: const InputDecoration(
                                              labelText: 'ProPW',
                                              hintText: '',
                                              border: UnderlineInputBorder(),
                                            ),
                                            onChanged: (value) {
                                              viewModel.proPW.text = value;
                                              AppSP.set(AppSPKey.proPW,
                                                  viewModel.proPW.text);
                                              viewModel.notifyListeners();
                                            },
                                          ),
                                        ),
                                        Focus(
                                          child: TextFormField(
                                            controller: viewModel.projectorIP,
                                            focusNode: FocusNode(),
                                            decoration: const InputDecoration(
                                              labelText: 'ProjectorIP ',
                                              hintText: '',
                                              border: UnderlineInputBorder(),
                                            ),
                                            onChanged: (value) {
                                              viewModel.projectorIP.text =
                                                  value;
                                              AppSP.set(AppSPKey.projectorIP,
                                                  viewModel.projectorIP.text);
                                              viewModel.notifyListeners();
                                            },
                                          ),
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
                                        const SizedBox(height: 10),
                                        Focus(
                                          child: TextFormField(
                                            focusNode: FocusNode(),
                                            decoration: const InputDecoration(
                                              labelText: 'Tên thiết bị',
                                              hintText: '',
                                              enabled: false,
                                              border: UnderlineInputBorder(),
                                            ),
                                            initialValue:
                                                homeVM.deviceInfo!.model,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Focus(
                                              child: Checkbox(
                                                checkColor: Colors.amber,
                                                activeColor: Colors.transparent,
                                                focusNode: FocusNode(),
                                                value: homeVM.turnOnlPJ,
                                                onChanged: (bool? value) {
                                                  homeVM.turnOnl();
                                                },
                                              ),
                                            ),
                                            const Text('Điều khiển mở PJ'),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Focus(
                                              child: Checkbox(
                                                checkColor: Colors.amber,
                                                activeColor: Colors.transparent,
                                                focusNode: FocusNode(),
                                                value: homeVM.turnOffPJ,
                                                onChanged: (bool? value) {
                                                  homeVM.turnOff();
                                                },
                                              ),
                                            ),
                                            const Text('Điều khiển tắt PJ'),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Focus(
                                              child: Checkbox(
                                                checkColor: Colors.amber,
                                                activeColor: Colors.transparent,
                                                focusNode: FocusNode(),
                                                value: homeVM.openOnStartup,
                                                onChanged: (bool? value) {
                                                  homeVM.openOnStart();
                                                },
                                              ),
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
                  FocusTraversalGroup(
                    policy: WidgetOrderTraversalPolicy(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Focus(
                          child: ButtomCustom(
                            width: 150,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            color: const Color(0xffEB6E2C),
                            onPressed: () async {
                              await homeVM.connectDevice();
                            },
                            title: 'KẾT NỐI',
                            textSize: 15,
                          ),
                        ),
                        Focus(
                          child: ButtomCustom(
                            width: 150,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            color: Colors.black,
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            title: 'THOÁT',
                            textSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
  }
}
