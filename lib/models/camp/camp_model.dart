
import 'time_run_model.dart';

class CampModel {
  String campaignId;
  String campaignName;
  String status;
  String videoId;
  String fromDate;
  String toDate;
  String fromTime;
  String toTime;
  String daysOfWeek;
  String videoType;
  String urlYoutube;
  String urlUSP;
  String computerId;
  List<TimeRunModel>? lstTimeRun;

  CampModel({
    required this.campaignId,
    required this.campaignName,
    required this.status,
    required this.videoId,
    required this.fromDate,
    required this.toDate,
    required this.fromTime,
    required this.toTime,
    required this.daysOfWeek,
    required this.videoType,
    required this.urlYoutube,
    required this.urlUSP,
    required this.computerId,
    required this.lstTimeRun,
  });

  factory CampModel.fromJson(Map<String, dynamic> json) {
    return CampModel(
      campaignId: json['campaign_id'] ?? '',
      campaignName: json['campaign_name'] ?? '',
      status: json['status'] ?? '',
      videoId: json['video_id'] ?? '',
      fromDate: json['from_date'] ?? '',
      toDate: json['to_date'] ?? '',
      fromTime: json['from_time'] ?? '',
      toTime: json['to_time'] ?? '',
      daysOfWeek: json['days_of_week'] ?? '',
      videoType: json['video_type'] ?? '',
      urlYoutube: json['url_youtobe'] ?? '',
      urlUSP: json['url_usp'] ?? '',
      computerId: json['computer_id'] ?? '',
      lstTimeRun: json['lstTimeRun'] ?? [],
    );
  }
}
