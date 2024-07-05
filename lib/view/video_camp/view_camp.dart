import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:video_player/video_player.dart';

import '../../view_models/home.vm.dart';
import '../../view_models/view_camp.vm.dart';
import 'ads.page.dart';

class ViewCamp extends StatefulWidget {
  HomeViewModel homeViewModel;

  ViewCamp({
    super.key,
    required this.homeViewModel,
  });

  @override
  State<ViewCamp> createState() => _ViewCampState();
}

class _ViewCampState extends State<ViewCamp> with WidgetsBindingObserver {
  late ViewCampViewModel viewCampViewModel;

  @override
  void initState() {
    viewCampViewModel = ViewCampViewModel(
      context: context,
      homeViewModel: widget.homeViewModel,
    );
    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      viewCampViewModel.pauseVideo = true;
    } else if (state == AppLifecycleState.resumed) {
      viewCampViewModel.pauseVideo = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ViewCampViewModel>.reactive(
      viewModelBuilder: () => viewCampViewModel,
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
