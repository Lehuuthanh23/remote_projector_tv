import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:video_player/video_player.dart';
import '../../app/app_sp.dart';
import '../../app/app_sp_key.dart';
import '../../models/camp/camp_schedule.dart';
import '../../view_models/view_camp.vm.dart';

class ViewCamp extends StatelessWidget {
  final List<CampSchedule> campSchedules;

  ViewCamp({
    Key? key,
    required this.campSchedules,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ViewCampViewModel>.reactive(
      disposeViewModel: false,
      viewModelBuilder: () => ViewCampViewModel(),
      onViewModelReady: (viewModel) => viewModel.init(campSchedules),
      builder: (context, viewModel, child) {
        return WillPopScope(
          onWillPop: () async {
            AppSP.set(AppSPKey.checkPlayVideo, 'false');
            viewModel.disposeViewModel();
            return true;
          },
          child: Scaffold(
            body: Stack(
              children: [
                Container(
                  color: Colors.black,
                ),
                Center(
                  child: viewModel.checkImage
                      ? (viewModel.campSchedule.videoType == 'url' &&
                                  viewModel.image == null) ||
                              viewModel.usbPaths.isEmpty
                          ? Image.network(
                              viewModel.campSchedule.urlYoutube,
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
                            ),
                ),
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
                        Text(
                          viewModel.checkUSB,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          '${viewModel.checkConnectUSB} : ${viewModel.checkPlay}',
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
