import 'package:flutter/material.dart';

import '../constants/app_color.dart';

class PopUpWidget extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? leftText;
  final String? rightText;
  final bool twoButton;
  final Function()? onLeftTap;
  final Function()? onRightTap;

  const PopUpWidget({
    super.key,
    required this.icon,
    required this.title,
    this.leftText,
    this.rightText,
    this.twoButton = false,
    required this.onLeftTap,
    this.onRightTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: FractionallySizedBox(
        widthFactor: 0.5,
        child: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColor.appBarEnd,
                  AppColor.appBarStart,
                ],
              ),
              borderRadius: BorderRadius.all(Radius.circular(6))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SizedBox(
                  height: 100,
                  child: icon,
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(
                height: 3,
                color: AppColor.white,
              ),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onLeftTap,
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(6)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            leftText ?? 'XÁC NHẬN',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 26),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (twoButton)
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onRightTap,
                          borderRadius: const BorderRadius.only(bottomRight: Radius.circular(6)),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              rightText ?? 'HỦY',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 26),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}