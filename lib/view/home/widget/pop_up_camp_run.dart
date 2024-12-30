import 'package:flutter/material.dart';

import '../../../models/camp/camp_model.dart';
import '../../../view_models/home.vm.dart';
import '../../../widget/button_custom.dart';
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
                  onPressed: () {
                    widget.vm.getValue();
                  },
                  title: 'NẠP LẠI',
                  textSize: 15,
                ),
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
