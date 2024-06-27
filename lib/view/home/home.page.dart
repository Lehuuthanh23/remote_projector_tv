import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:play_box/app/app_sp.dart';
import 'package:play_box/app/app_sp_key.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../models/camp/camp_schedule.dart';
import '../../request/camp/camp.request.dart';
import '../../view_models/home.vm.dart';
import '../../widget/buttonCustom.dart';
import '../../widget/clock.dart';
import '../timer_clock/timer_clock.dart';
import 'widget/pop_up_camp_run.dart';
import 'widget/pop_up_setting.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeViewModel homeViewModel = HomeViewModel();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    homeViewModel.setContext(context);
  }

  String check = 'Chưa check';
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      disposeViewModel: false,
      viewModelBuilder: () => homeViewModel,
      onViewModelReady: (viewModel) async {
        viewModel.viewContext = context;
        await viewModel.initialise();
      },
      builder: (context, viewModel, child) {
        viewModel.viewContext = context;
        return SafeArea(
          child: Scaffold(
            body: Stack(
              children: [
                // Nền chính của ứng dụng
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
                            'assets/images/ic_projector.png',
                            width: 150,
                            height: 150,
                          ),
                          const Text(
                            'REMOTE PROJECTOR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 25,
                            ),
                          ),
                        ],
                      ).centered(),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ButtomCustom(
                            width: 150,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            isSplashScreen: true,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: PopupCampRunScreen(
                                      camps: viewModel.camps,
                                      vm: viewModel,
                                    ),
                                  );
                                },
                              );
                            },
                            title: 'DANH SÁCH CAMP',
                            textSize: 15,
                          ),
                          ButtomCustom(
                            width: 150,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            isSplashScreen: true,
                            onPressed: () {
                              showDialog(
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
                            },
                            title: 'CÀI ĐẶT',
                            textSize: 15,
                          ),
                          ButtomCustom(
                            width: 150,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            color: Colors.black,
                            onPressed: () => viewModel.signOut(),
                            title: 'THOÁT',
                            textSize: 15,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CupertinoSwitch(
                                  value: bool.parse(
                                      AppSP.get(AppSPKey.checkPlayVideo) ??
                                          'true'),
                                  onChanged: (check) =>
                                      viewModel.playCamp(check)),
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
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
                // Màn hình tối mờ khi Drawer mở
                if (viewModel.isDrawerOpen)
                  Positioned.fill(
                    child: WillPopScope(
                      onWillPop: () async {
                        viewModel.toggleDrawer();
                        return false;
                      },
                      child: GestureDetector(
                        onTap: viewModel.toggleDrawer,
                        child: Container(
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                // Drawer tùy chỉnh
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  left: viewModel.isDrawerOpen
                      ? 0
                      : -MediaQuery.of(context).size.width / 2,
                  top: 0,
                  bottom: 0,
                  child: FocusScope(
                    canRequestFocus: viewModel.isDrawerOpen,
                    child: Container(
                      width: MediaQuery.of(context).size.width / 2,
                      color: Colors.black26,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 40),
                      child: ListView.builder(
                        itemCount: viewModel.lstCampSchedule.length,
                        itemBuilder: (context, index) {
                          final camp = viewModel.lstCampSchedule[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  print('Nhấn vào camp: ${camp.campaignName}'),
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
                                        Text(
                                          camp.campaignName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 20,
                                            color: Colors.white,
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
                  ),
                ),
                // Nút mở Drawer
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
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
              ],
            ),
          ),
        );
      },
    );
  }
}
