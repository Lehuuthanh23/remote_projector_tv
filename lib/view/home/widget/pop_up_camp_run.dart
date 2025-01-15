import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:play_box/view/home/widget/sync_progress_dialog.dart';

import '../../../models/camp/camp_model.dart';
import '../../../view_models/home.vm.dart';
import '../../../widget/button_custom.dart';
import '../../../widget/pop_up.dart';
import 'camp_card.dart';

class PopupCampRunScreen extends StatefulWidget {
  final List<CampModel> camps;
  final HomeViewModel vm;

  const PopupCampRunScreen({
    super.key,
    required this.camps,
    required this.vm,
  });

  @override
  State<PopupCampRunScreen> createState() => _PopupCampRunScreenState();
}

class _PopupCampRunScreenState extends State<PopupCampRunScreen> {
  List<CampModel> camps = [];

  @override
  void initState() {
    super.initState();
    camps = widget.camps;
    widget.vm.addListener(_updateCamps);
  }

  @override
  void dispose() {
    widget.vm.removeListener(_updateCamps);
    super.dispose();
  }

  void _updateCamps() {
    setState(() {
      camps = widget.vm.camps;
    });
  }

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
                'DANH SÁCH VIDEO',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: camps.length,
                itemBuilder: (context, index) {
                  return CampCard(
                    camp: camps[index],
                    focusNode: FocusNode(),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ButtonCustom(
                  width: 150,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  isSplashScreen: false,
                  onPressed: () async {
                    bool hasInternet =
                        await InternetConnection().hasInternetAccess;
                    if (hasInternet) {
                      widget.vm.getValue();
                      showDialog(
                          context: context,
                          builder: (context) {
                            return SyncProgressDialog(
                                viewCampViewModel: widget.vm.viewCampViewModel);
                          });
                      await widget.vm.viewCampViewModel.syncVideo();
                      Navigator.of(context).pop();
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) {
                          Future.delayed(const Duration(seconds: 3), () {
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          });

                          return PopUpWidget(
                            icon: Image.asset("assets/images/ic_error.png"),
                            title: 'Không có kết nối Internet',
                            leftText: 'Xác nhận',
                            onLeftTap: () {
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      );
                    }
                  },
                  title: 'NẠP LẠI',
                  textSize: 15,
                ),
                // ButtonCustom(
                //   width: 150,
                //   padding: const EdgeInsets.symmetric(vertical: 10),
                //   isSplashScreen: false,
                //   onPressed: () {
                //     widget.vm.viewCampViewModel.deleteVideosDirectory();
                //   },
                //   title: 'Xóa bộ nhớ',
                //   textSize: 15,
                // ),
                ButtonCustom(
                  width: 150,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  isSplashScreen: false,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  title: 'THOÁT',
                  textSize: 15,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
