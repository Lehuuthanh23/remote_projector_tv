import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../constants/app_color.dart';
import '../../view_models/view_camp.vm.dart';

class ADSPage extends StatefulWidget {
  const ADSPage({super.key, required this.viewCampViewModel});
  final ViewCampViewModel viewCampViewModel;
  @override
  State<ADSPage> createState() => _ADSPageState();
}

class _ADSPageState extends State<ADSPage> {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ViewCampViewModel>.reactive(
        disposeViewModel: false,
        viewModelBuilder: () => widget.viewCampViewModel,
        onViewModelReady: (viewModel) {
          // viewModel.init();
          // viewModel.syncVideo();
        },
        builder: (context, viewModel, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
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
            child: Center(
              child: SizedBox(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/ts_screen.png',
                            width: 100,
                            height: 100,
                          ),
                          const Text(
                            'TS Screen',
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 25,
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            '0907 859 668',
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 500,
                            child: LinearProgressIndicator(
                                value: viewModel.totalProgress),
                          ),
                          Text(
                            '${(viewModel.totalProgress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            viewModel.currentTask,
                            style: const TextStyle(
                                fontSize: 14, fontStyle: FontStyle.italic),
                          ),
                          // ElevatedButton(
                          //     onPressed: () {
                          //       viewModel.deleteVideosDirectory();
                          //     },
                          //     child: const Text('Xóa video')),
                          // ElevatedButton(
                          //     onPressed: () {
                          //       viewModel.syncVideo();
                          //     },
                          //     child: const Text('Đồng bộ')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
