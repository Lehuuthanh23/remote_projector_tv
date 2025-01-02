import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../app/app_utils.dart';
import '../../constants/app_color.dart';
import '../../view_models/home.vm.dart';
import '../../widget/button_custom.dart';
import '../timer_clock/timer_clock.dart';
import 'widget/pop_up_camp_run.dart';
import 'widget/pop_up_setting.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(context: context),
      onViewModelReady: (viewModel) async {
        await viewModel.initialise();
        viewModel.checkConnectDevice = await AppUtils.checkConnect();
        if (viewModel.checkConnectDevice == true) {
          viewModel.playCamp(true);
        } else {
          viewModel.playVideo = false;
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: PopupSettingScreen(
                  homeVM: viewModel,
                ),
              );
            },
          );
        }
      },
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Scaffold(
            body: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFEB6E2C),
                        Color(0xFFFABD1D),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Spacer(),
                      Column(
                        children: [
                          Image.asset(
                            'assets/images/ts_screen.png',
                            width: 100,
                            height: 100,
                          ),
                          const Text(
                            'TS Screen',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 25,
                            ),
                          ),
                        ],
                      ).centered(),
                      const Spacer(),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ButtonCustom(
                                focus: !viewModel.updateAvailable,
                                width: 200,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                isSplashScreen: true,
                                onPressed: () {
                                  // viewModel.dpc.clearDeviceOwnerApp();
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: PopupCampRunScreen(
                                          camps: viewModel.camps,
                                          vm: viewModel,
                                        ),
                                      );
                                    },
                                  );
                                },
                                title: 'DANH SÁCH VIDEO',
                                textSize: 15,
                              ),
                              ButtonCustom(
                                focus: !viewModel.updateAvailable,
                                width: 150,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                isSplashScreen: true,
                                onPressed: () {
                                  showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: PopupSettingScreen(
                                          homeVM: viewModel,
                                        ),
                                      );
                                    },
                                  );
                                },
                                title: 'CÀI ĐẶT',
                                textSize: 15,
                              ),
                              ButtonCustom(
                                focus: !viewModel.updateAvailable,
                                isSplashScreen: true,
                                width: 150,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                onPressed: () => {
                                  // viewModel.dpc.clearDeviceOwnerApp()
                                  viewModel.signOut(),
                                },
                                title: 'THOÁT',
                                textSize: 15,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  CupertinoSwitch(
                                      value: viewModel.playVideo,
                                      onChanged: (check) {
                                        if (viewModel.checkConnectDevice) {
                                          viewModel.playCamp(check);
                                        }
                                      }),
                                  const Text(
                                    'Tự động chạy',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ],
                              ),
                              TimerClock(
                                homeViewModel: viewModel,
                              ),
                            ],
                          ),
                          if (viewModel.newVersion)
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.only(left: 30),
                              width: MediaQuery.of(context).size.width,
                              color: Colors.white,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Vui lòng cập nhật ứng dụng lên phiên bản mới nhất | Phiên bản: ${viewModel.configModel?.appTVBoxVersion ?? ''} | Ngày phát hành: ${viewModel.configModel?.appTVBoxBuildDate ?? ''}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 50, bottom: 10, top: 10),
                                    child: ButtonCustom(
                                      width: 150,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      color: Colors.amber,
                                      onPressed: () =>
                                          viewModel.updateAndroidApp(viewModel
                                              .configModel?.appTVBoxUpdateUrl),
                                      title: 'Cập nhật',
                                      textSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (!viewModel.newVersion)
                        const SizedBox(
                          height: 20,
                        ),
                    ],
                  ),
                ),
                if (viewModel.isDrawerOpen)
                  Positioned.fill(
                    child: PopScope(
                      canPop: false,
                      onPopInvokedWithResult: (didPop, _) {
                        if (!didPop) {
                          viewModel.toggleDrawer();
                        }
                      },
                      child: GestureDetector(
                        onTap: viewModel.toggleDrawer,
                        child: Container(
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  left: viewModel.isDrawerOpen
                      ? 0
                      : -MediaQuery.of(context).size.width,
                  top: 0,
                  bottom: 0,
                  child: FocusScope(
                    canRequestFocus: viewModel.isDrawerOpen,
                    child: Stack(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width >
                                  MediaQuery.of(context).size.height
                              ? MediaQuery.of(context).size.width / 2
                              : MediaQuery.of(context).size.width,
                          color: Colors.black26,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 60),
                          child: ListView.builder(
                            itemCount: viewModel.lstCampSchedule.length,
                            itemBuilder: (context, index) {
                              final camp = viewModel.lstCampSchedule[index];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {},
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 20),
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${camp.fromTime.substring(0, 5)} - ${camp.toTime.substring(0, 5)}',
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.white),
                                            ),
                                            const SizedBox(width: 50),
                                            Expanded(
                                              child: Text(
                                                camp.campaignName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 20,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        const Divider(
                                          color: Colors.white,
                                          height: 1,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton(
                              focusColor: Colors.black12,
                              onPressed: viewModel.toggleDrawer,
                              icon: const Icon(
                                Icons.close,
                                size: 30,
                                color: Colors.white,
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                // Nút mở Drawer
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  left: viewModel.isDrawerOpen ? -50 : 10,
                  top: 20,
                  child: AnimatedOpacity(
                    opacity: viewModel.isDrawerOpen ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: IconButton(
                      icon:
                          const Icon(Icons.menu, color: Colors.white, size: 30),
                      onPressed: viewModel.toggleDrawer,
                    ),
                  ),
                ),

                if (viewModel.updateAvailable)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: AppColor.black.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColor.white,
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        padding: const EdgeInsets.all(20),
                        width: 400,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Tải xuống bản cập nhật',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppColor.black,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  '${viewModel.tempPath != null ? 'Đã tải xong' : viewModel.isUpdate ? 'Đang tải' : 'Tạm dừng'}${viewModel.isUpdate ? ':' : ''} ',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppColor.black,
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                            TextSpan(
                                              text: viewModel.isUpdate
                                                  ? '${(viewModel.progress * 100).toStringAsFixed(2)} %'
                                                  : '',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppColor.black,
                                                fontWeight: FontWeight.w400,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (viewModel.isUpdate)
                                  const SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: CircularProgressIndicator(),
                                  ),
                              ],
                            ),
                            ButtonCustom(
                              onPressed: viewModel.cancelDownloadTaped,
                              title: viewModel.tempPath != null
                                  ? 'Cài đặt'
                                  : viewModel.isUpdate
                                      ? 'Hủy'
                                      : 'Tải xuống',
                              color: Colors.amber,
                              textSize: 20,
                              margin: const EdgeInsets.only(top: 20),
                            ),
                          ],
                        ),
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
