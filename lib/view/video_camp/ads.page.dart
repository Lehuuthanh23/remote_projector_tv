import 'package:flutter/material.dart';

import '../../constants/app_color.dart';

class ADSPage extends StatelessWidget {
  const ADSPage({super.key});

  @override
  Widget build(BuildContext context) {
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
              Image.asset(
                'assets/images/ic_projector.png',
                width: 150,
                height: 150,
              ),
              const Text(
                'TS Screen TV',
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
      ),
    );
  }
}
