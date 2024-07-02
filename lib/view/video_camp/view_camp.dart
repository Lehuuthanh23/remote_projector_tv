import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:video_player/video_player.dart';

import '../../app/app_sp.dart';
import '../../app/app_sp_key.dart';
import '../../models/camp/camp_schedule.dart';
import '../../view_models/view_camp.vm.dart';

class ViewCamp extends StatelessWidget {
  final List<CampSchedule> campSchedules;

  const ViewCamp({
    super.key,
    required this.campSchedules,
  });

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ViewCampViewModel>.reactive(
      viewModelBuilder: () => ViewCampViewModel(
        campSchedulesNew: campSchedules,
        context: context,
      ),
      onViewModelReady: (viewModel) {
        viewModel.init();
      },
      builder: (context, viewModel, child) {
        return WillPopScope(
          onWillPop: () async {
            AppSP.set(AppSPKey.checkPlayVideo, 'false');
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
                      ? (viewModel.campSchedulesNew[viewModel.currentIndex]
                                          .videoType ==
                                      'url' &&
                                  viewModel.image == null) ||
                              viewModel.usbPaths.isEmpty
                          ? Image.network(
                              viewModel.campSchedulesNew[viewModel.currentIndex]
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
