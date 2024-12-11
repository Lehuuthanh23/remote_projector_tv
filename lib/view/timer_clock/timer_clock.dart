import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../view_models/home.vm.dart';
import '../../view_models/timer_clock.vm.dart';

class TimerClock extends StatelessWidget {
  final HomeViewModel homeViewModel;

  const TimerClock({super.key, required this.homeViewModel});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<TimerClockViewModel>.reactive(
      viewModelBuilder: () => TimerClockViewModel(
        viewContext: context,
        homeViewModel: homeViewModel,
      ),
      onViewModelReady: (model) {
        model.initialize();
      },
      builder: (context, model, child) => Center(
        child: Text(
          model.currentTimeFormatted,
          style: const TextStyle(fontSize: 35),
        ),
      ),
    );
  }
}
