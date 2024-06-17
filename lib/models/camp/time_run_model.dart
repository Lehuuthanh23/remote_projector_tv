class TimeRunModel {
  String? idRun;
  String? campaignId;
  String fromTime;
  String toTime;

  TimeRunModel({
    this.campaignId,
    this.idRun,
    required this.fromTime,
    required this.toTime,
  });

  factory TimeRunModel.fromJson(Map<String, dynamic> json) {
    return TimeRunModel(
      campaignId: json['campaign_id'],
      idRun: json['id_run'],
      fromTime: json['from_time'],
      toTime: json['to_time'],
    );
  }
}
