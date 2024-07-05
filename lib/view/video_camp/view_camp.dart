import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:play_box/view/video_camp/ads.page.dart';
import 'package:play_box/view_models/home.vm.dart';
import 'package:stacked/stacked.dart';
import 'package:video_player/video_player.dart';

import '../../app/app_sp.dart';
import '../../app/app_sp_key.dart';
import '../../models/camp/camp_schedule.dart';
import '../../view_models/view_camp.vm.dart';

class ViewCamp extends StatefulWidget {
  HomeViewModel homeViewModel;
  ViewCamp({
    super.key,
    required this.homeViewModel,
  });

  @override
  State<ViewCamp> createState() => _ViewCampState();
}

class _ViewCampState extends State<ViewCamp> {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ViewCampViewModel>.reactive(
      viewModelBuilder: () => ViewCampViewModel(
        context: context,
        homeViewModel: widget.homeViewModel,
      ),
      onViewModelReady: (viewModel) {
        viewModel.init();
      },
      builder: (context, viewModel, child) {
        return WillPopScope(
          onWillPop: () async {
            viewModel.popPage();
            widget.homeViewModel.playVideo = false;
            return true;
          },
          child: Scaffold(
            body: Stack(
              children: [
                Container(
                  color: Colors.black,
                ),
                Center(
                    child: viewModel.isPlaying && viewModel.isPlaying
                        ? (viewModel.checkImage
                            ? (viewModel
                                                .campSchedulesNew[
                                                    viewModel.currentIndex]
                                                .videoType ==
                                            'url' &&
                                        viewModel.image == null) ||
                                    viewModel.usbPaths.isEmpty
                                ? Image.network(
                                    viewModel
                                        .campSchedulesNew[
                                            viewModel.currentIndex]
                                        .urlYoutube,
                                    fit: BoxFit.fill,
                                  )
                                : viewModel.image != null
                                    ? Image.file(
                                        viewModel.image!,
                                        fit: BoxFit.fill,
                                      )
                                    : Container(
                                        color: Colors.black,
                                      )
                            : viewModel.controller != null &&
                                    viewModel.controller!.value.isInitialized
                                ? AspectRatio(
                                    aspectRatio:
                                        viewModel.controller!.value.aspectRatio,
                                    child: VideoPlayer(viewModel.controller!),
                                  )
                                : Container(
                                    color: Colors.black,
                                  ))
                        : const ADSPage()),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          viewModel.formattedTime,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ],
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
