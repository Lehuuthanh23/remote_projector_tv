import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../view_models/home.vm.dart';
import '../../widget/buttonCustom.dart';
import '../../widget/clock.dart';
import 'widget/pop_up_camp_run.dart';
import 'widget/pop_up_setting.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isDrawerOpen = false;

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      disposeViewModel: false,
      viewModelBuilder: () => HomeViewModel(),
      onViewModelReady: (viewModel) async {
        viewModel.viewContext = context;
        await viewModel.initialise();
      },
      builder: (context, viewModel, child) {
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
                          const TimerClock(),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
                // Màn hình tối mờ khi Drawer mở
                if (_isDrawerOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _toggleDrawer,
                      child: Container(
                        color: Colors.black54,
                      ),
                    ),
                  ),
                // Drawer tùy chỉnh
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  left: _isDrawerOpen
                      ? 0
                      : -MediaQuery.of(context).size.width / 2,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: MediaQuery.of(context).size.width / 2,
                    color: Colors.black26,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 40),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...viewModel.lstCampSchedule
                              .map((camp) => Container(
                                  margin: const EdgeInsets.only(top: 20),
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                      border: Border(
                                          bottom:
                                              BorderSide(color: Colors.white))),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${camp!.fromTime.substring(0, 5)} - ${camp.toTime.substring(0, 5)}',
                                        style: const TextStyle(
                                            fontSize: 20, color: Colors.white),
                                      ),
                                      const SizedBox(
                                        width: 50,
                                      ),
                                      Text(
                                        camp.campaignName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 20,
                                            color: Colors.white),
                                      ),
                                    ],
                                  )))
                              .toList(),
                        ],
                      ),
                    ),
                  ),
                ),
                // Nút mở Drawer
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  left: _isDrawerOpen ? -50 : 10,
                  top: 20,
                  child: AnimatedOpacity(
                    opacity: _isDrawerOpen ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: IconButton(
                      icon:
                          const Icon(Icons.menu, color: Colors.white, size: 30),
                      onPressed: _toggleDrawer,
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
