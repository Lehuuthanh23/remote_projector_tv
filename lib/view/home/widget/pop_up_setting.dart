import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:stacked/stacked.dart';

import '../../../app/app_sp.dart';
import '../../../app/app_sp_key.dart';
import '../../../app/app_utils.dart';
import '../../../models/device/device_info_model.dart';
import '../../../models/device/device_model.dart';
import '../../../models/dir/dir_model.dart';
import '../../../models/user/user.dart';
import '../../../request/device/device.request.dart';
import '../../../view_models/home.vm.dart';
import '../../../widget/button_custom.dart';
import '../../../widget/pop_up.dart';

class PopupSettingScreen extends StatefulWidget {
  const PopupSettingScreen({super.key, required this.homeVM});

  final HomeViewModel homeVM;

  @override
  State<PopupSettingScreen> createState() => _PopupSettingScreenState();
}

class _PopupSettingScreenState extends State<PopupSettingScreen> {
  String _selectedSource = "USB";
  bool? _checkConnect;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
        disposeViewModel: false,
        viewModelBuilder: () => widget.homeVM,
        onViewModelReady: (viewModel) async {
          _selectedSource = AppSP.get(AppSPKey.typePlayVideo) ?? 'USB';
          _checkConnect = await AppUtils.checkConnect();
          await viewModel.getDir();
          viewModel.kioskMode = AppSP.get(AppSPKey.isKioskMode) ?? false;
          viewModel.notifyListeners();
        },
        builder: (context, viewModel, child) {
          return Center(
            child: Container(
              color: Colors.grey.shade100,
              child: viewModel.isBusy
                  ? const CircularProgressIndicator()
                  : Column(
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
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
                                                        color:
                                                            Color(0xff797979),
                                                        fontSize: 15),
                                                  ),
                                                  Text(
                                                    widget.homeVM.currentUser
                                                        .customerName!,
                                                    style: const TextStyle(
                                                        fontSize: 20),
                                                  ),
                                                ],
                                              ),
                                              prefixIcon: Image.asset(
                                                  'assets/images/ic_profile.png'),
                                              border:
                                                  const OutlineInputBorder(),
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
                                                        color:
                                                            Color(0xff797979),
                                                        fontSize: 15),
                                                  ),
                                                  Text(
                                                    widget.homeVM.currentUser
                                                        .phoneNumber!,
                                                    style: const TextStyle(
                                                        fontSize: 20),
                                                  ),
                                                ],
                                              ),
                                              prefixIcon: Image.asset(
                                                  'assets/images/ic_phone_number.png'),
                                              border:
                                                  const OutlineInputBorder(),
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
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextFormField(
                                                      enabled: false,
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: widget
                                                                    .homeVM
                                                                    .deviceInfo
                                                                    ?.serialNumber ==
                                                                'unknown'
                                                            ? 'ANDROID ID'
                                                            : 'SERI NUMBER',
                                                        hintText: '',
                                                        enabled: false,
                                                        border:
                                                            const UnderlineInputBorder(),
                                                      ),
                                                      initialValue: widget
                                                                  .homeVM
                                                                  .deviceInfo
                                                                  ?.serialNumber ==
                                                              'unknown'
                                                          ? widget
                                                              .homeVM
                                                              .deviceInfo!
                                                              .androidId
                                                          : widget
                                                              .homeVM
                                                              .deviceInfo
                                                              ?.serialNumber,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 200,
                                                    height: 50,
                                                    child:
                                                        DropdownButtonFormField<
                                                            Dir>(
                                                      focusNode: viewModel
                                                          .focusNodeSelectDir,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black),
                                                      itemHeight: 30,
                                                      decoration:
                                                          InputDecoration(
                                                        labelText:
                                                            "Chọn hệ thống",
                                                        hintText:
                                                            "Chọn hệ thống",
                                                        labelStyle:
                                                            const TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .black),
                                                        hintStyle:
                                                            const TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .black),
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      4.0),
                                                          borderSide:
                                                              const BorderSide(
                                                                  color: Colors
                                                                      .grey),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      4.0),
                                                          borderSide:
                                                              const BorderSide(
                                                                  color: Colors
                                                                      .red),
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      4.0),
                                                          borderSide:
                                                              const BorderSide(
                                                                  color: Colors
                                                                      .grey),
                                                        ),
                                                      ),
                                                      value:
                                                          viewModel.selectedDir,
                                                      items: [
                                                        ...viewModel.listDirAll
                                                            .map((dir) {
                                                          return DropdownMenuItem<
                                                              Dir>(
                                                            value: dir,
                                                            child: Text(
                                                                dir.dirName ??
                                                                    ''),
                                                          );
                                                        }),
                                                      ],
                                                      onChanged: (Dir? value) {
                                                        viewModel
                                                            .onChangeDir(value);
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Trạng thái',
                                                  hintText: '',
                                                  enabled: false,
                                                  border:
                                                      UnderlineInputBorder(),
                                                ),
                                                initialValue: 'Đang chạy',
                                              ),
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Tên thiết bị',
                                                  hintText: '',
                                                  enabled: false,
                                                  border:
                                                      UnderlineInputBorder(),
                                                ),
                                                initialValue: widget
                                                    .homeVM.deviceInfo?.model,
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
                                                      focusNode: viewModel
                                                          .focusNodeProUN,
                                                      nextFocusNode: viewModel
                                                          .focusNodeProPW,
                                                      label: 'ProUN',
                                                      controller: viewModel
                                                          .proUNController,
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
                                                      focusNode: viewModel
                                                          .focusNodeProPW,
                                                      nextFocusNode: viewModel
                                                          .focusNodeProIP,
                                                      label: 'ProPW',
                                                      controller: viewModel
                                                          .proPWController,
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
                                                      focusNode: viewModel
                                                          .focusNodeProIP,
                                                      nextFocusNode: viewModel
                                                          .focusNodeOpenPJ,
                                                      label: 'ProjectorIP',
                                                      controller: viewModel
                                                          .proIPController,
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
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          Checkbox(
                                                            checkColor:
                                                                Colors.amber,
                                                            activeColor: Colors
                                                                .transparent,
                                                            focusNode: viewModel
                                                                .focusNodeOpenPJ,
                                                            value: widget.homeVM
                                                                .turnOnlPJ,
                                                            onChanged:
                                                                (bool? value) {
                                                              widget.homeVM
                                                                  .turnOnl();
                                                            },
                                                          ),
                                                          const Text(
                                                              'Điều khiển mở PJ'),
                                                        ],
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          Checkbox(
                                                            checkColor:
                                                                Colors.amber,
                                                            activeColor: Colors
                                                                .transparent,
                                                            focusNode: viewModel
                                                                .focusNodeClosePJ,
                                                            value: widget.homeVM
                                                                .turnOffPJ,
                                                            onChanged:
                                                                (bool? value) {
                                                              widget.homeVM
                                                                  .turnOff();
                                                            },
                                                          ),
                                                          const Text(
                                                              'Điều khiển tắt PJ'),
                                                        ],
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          Checkbox(
                                                            checkColor:
                                                                Colors.amber,
                                                            activeColor: Colors
                                                                .transparent,
                                                            focusNode: viewModel
                                                                .focusNodeOpenOnStart,
                                                            value: widget.homeVM
                                                                .openOnStartup,
                                                            onChanged:
                                                                (bool? value) {
                                                              widget.homeVM
                                                                  .openOnStart();
                                                            },
                                                          ),
                                                          const Text(
                                                              'Mở khi khởi động'),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    width: 30,
                                                  ),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        const Align(
                                                            alignment: Alignment
                                                                .centerLeft,
                                                            child: Text(
                                                                'Chạy từ nguồn:')),
                                                        Column(
                                                          children: [
                                                            ListTile(
                                                              title: const Text(
                                                                  'USB'),
                                                              leading:
                                                                  Radio<String>(
                                                                focusNode: viewModel
                                                                    .focusNodeUSB,
                                                                value: 'USB',
                                                                groupValue:
                                                                    _selectedSource,
                                                                onChanged:
                                                                    (String?
                                                                        value) {
                                                                  setState(() {
                                                                    _selectedSource =
                                                                        value!;
                                                                    AppSP.set(
                                                                        AppSPKey
                                                                            .typePlayVideo,
                                                                        _selectedSource);
                                                                  });
                                                                },
                                                              ),
                                                            ),
                                                            ListTile(
                                                              title: const Text(
                                                                  'Chiến dịch'),
                                                              leading:
                                                                  Radio<String>(
                                                                value:
                                                                    'Chiendich',
                                                                groupValue:
                                                                    _selectedSource,
                                                                focusNode: viewModel
                                                                    .focusNodeCamp,
                                                                onChanged:
                                                                    (String?
                                                                        value) {
                                                                  setState(() {
                                                                    _selectedSource =
                                                                        value!;
                                                                    AppSP.set(
                                                                        AppSPKey
                                                                            .typePlayVideo,
                                                                        _selectedSource);
                                                                  });
                                                                },
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  )
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
                            ButtonCustom(
                              width: 150,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              color: _checkConnect == null
                                  ? const Color(0xff9a9a9a)
                                  : null,
                              isSplashScreen: false,
                              onPressed: () async {
                                bool hasInternet = await InternetConnection()
                                    .hasInternetAccess;
                                if (hasInternet) {
                                  _checkConnect = await AppUtils.checkConnect();
                                  if (_checkConnect == false) {
                                    await widget.homeVM.connectDevice();
                                  }
                                  AppSP.set(AppSPKey.proPW,
                                      viewModel.proPWController.text);
                                  AppSP.set(AppSPKey.proUN,
                                      viewModel.proUNController.text);
                                  AppSP.set(AppSPKey.projectorIP,
                                      viewModel.proIPController.text);
                                  if (_checkConnect == true) {
                                    await viewModel.updateDirByDevice();
                                  }
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      Future.delayed(const Duration(seconds: 3),
                                          () {
                                        if (context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                      });

                                      return PopUpWidget(
                                        icon: Image.asset(
                                            "assets/images/ic_error.png"),
                                        title: 'Không có kết nối Internet',
                                        leftText: 'Xác nhận',
                                        onLeftTap: () {
                                          Navigator.of(context).pop();
                                        },
                                      );
                                    },
                                  );
                                }
                              },
                              title: _checkConnect == true ? 'LƯU' : 'KẾT NỐI',
                              textSize: 15,
                            ),
                            ButtonCustom(
                              width: 150,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              isSplashScreen: false,
                              onPressed: () async {
                                viewModel.openSettings();
                              },
                              title: 'Cài đặt Wifi',
                              textSize: 15,
                            ),
                            ButtonCustom(
                              width: 150,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              isSplashScreen: false,
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              title: 'THOÁT',
                              textSize: 15,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CupertinoSwitch(
                                    value: viewModel.kioskMode,
                                    onChanged: (check) {
                                      viewModel.changeKioskMode(check);
                                    }),
                                const Text(
                                  'Kiosk mode',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
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
    required this.focusNode,
    required this.nextFocusNode,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final FocusNode focusNode;
  final FocusNode nextFocusNode;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: enabled ? focusNode : null,
      readOnly: !enabled,
      cursorColor: Colors.black,
      onFieldSubmitted: (_) {
        if (enabled) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
      },
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
