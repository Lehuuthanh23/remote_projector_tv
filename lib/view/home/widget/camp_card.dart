import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../models/camp/camp_model.dart';

class CampCard extends StatelessWidget {
  final CampModel camp;

  const CampCard({Key? key, required this.camp}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tách các ngày trong tuần từ chuỗi daysOfWeek
    final days = camp.daysOfWeek.split(',');

    // Tách các thời gian từ chuỗi fromTime và toTime
    List<String> times = camp.lstTimeRun!
        .map((timeRun) =>
            '${timeRun.fromTime.substring(0, 5)} - ${timeRun.toTime.substring(0, 5)}')
        .toList();

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.shade200,
          )),
      margin: const EdgeInsets.only(top: 10, right: 10, left: 10),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/ic_camp_color.png',
              width: 70,
              height: 70,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          camp.campaignName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Text(
                        "Trạng thái: ",
                      ),
                      Text(camp.status == '1' ? 'Đang chạy' : 'Đã tắt',
                          style: TextStyle(
                              color: camp.status == '1'
                                  ? Colors.green
                                  : Colors.red))
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Text("Hàng ngày: "),
                            ...days.map((day) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0),
                                      decoration: const BoxDecoration(
                                          color: Color(0xffE5E5E5)),
                                      child: Text(
                                        day,
                                        style: const TextStyle(
                                            color: Color(0xffEB6E2C)),
                                      )),
                                )),
                          ],
                        ),
                      ),
                      Text(
                          "Bắt đầu: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(camp.fromDate))}"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Text("Giờ chạy: "),
                            ...times.map((time) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0),
                                      decoration: const BoxDecoration(
                                          color: Color(0xffE5E5E5)),
                                      child: Text(
                                        time,
                                        style: const TextStyle(
                                            color: Color(0xffEB6E2C)),
                                      )),
                                )),
                          ],
                        ),
                      ),
                      Text(
                          "Kết thúc: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(camp.toDate))}"),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
