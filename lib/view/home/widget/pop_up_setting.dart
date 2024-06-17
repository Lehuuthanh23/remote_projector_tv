import 'package:flutter/material.dart';
import '../../../view_models/home.vm.dart';
import '../../../widget/buttonCustom.dart';

class PopupSettingScreen extends StatelessWidget {
  const PopupSettingScreen({Key? key, required this.homeVM}) : super(key: key);
  final HomeViewModel homeVM;
  @override
  Widget build(BuildContext context) {
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
                                          homeVM.currentUser.customerName!,
                                          style: const TextStyle(fontSize: 20),
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
                                          style: const TextStyle(fontSize: 20),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Focus(
                                    child: TextFormField(
                                      focusNode: FocusNode(),
                                      decoration: const InputDecoration(
                                        labelText: 'Tên thiết bị',
                                        hintText: '',
                                        enabled: false,
                                        border: UnderlineInputBorder(),
                                      ),
                                      initialValue: homeVM.deviceInfo!.model,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Điều khiển mở PJ'),
                                      Focus(
                                        child: Checkbox(
                                          focusNode: FocusNode(),
                                          value: false,
                                          onChanged: (bool? value) {},
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Điều khiển tắt PJ'),
                                      Focus(
                                        child: Checkbox(
                                          focusNode: FocusNode(),
                                          value: false,
                                          onChanged: (bool? value) {},
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Mở khi khởi động'),
                                      Focus(
                                        child: Checkbox(
                                          focusNode: FocusNode(),
                                          value: false,
                                          onChanged: (bool? value) {},
                                        ),
                                      ),
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
                      onPressed: () {
                        
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
  }
}
