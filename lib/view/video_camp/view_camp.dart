import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';
import 'package:video_player/video_player.dart';

import '../../view_models/home.vm.dart';
import '../../view_models/view_camp.vm.dart';
import 'ads.page.dart';

class ViewCamp extends StatefulWidget {
  final HomeViewModel homeViewModel;

  const ViewCamp({super.key, required this.homeViewModel});

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
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      viewModel.formattedTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
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
                            itemCount: viewModel.campSchedulesNew.length,
                            itemBuilder: (context, index) {
                              final camp = viewModel.campSchedulesNew[index];
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
                        Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton(
                              focusColor: Colors.black12,
                              onPressed: () {
                                FocusScope.of(context)
                                    .requestFocus(viewModel.drawerFocus);
                                viewModel.toggleDrawer();
                              },
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
                    child: FocusScope(
                      autofocus: true,
                      onKey: (FocusNode node, RawKeyEvent event) {
                        if (event is RawKeyDownEvent) {
                          switch (event.logicalKey.keyLabel) {
                            case 'Arrow Up':
                            case 'Arrow Down':
                            case 'Arrow Left':
                            case 'Arrow Right':
                            case 'Enter':
                              viewModel.toggleDrawer();
                              return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: IconButton(
                        icon: const Icon(Icons.menu,
                            color: Colors.white, size: 30),
                        onPressed: viewModel.toggleDrawer,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
