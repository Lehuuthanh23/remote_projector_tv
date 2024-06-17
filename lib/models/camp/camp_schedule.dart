class CampSchedule {
  String campaignId;
  String campaignName;
  String fromDate;
  String toDate;
  String status;
  String videoType;
  String urlYoutube;
  String urlUsp;
  String daysOfWeek;
  String deleted;
  String customerId;
  String fromTime;
  String toTime;
  String videoDuration;
  CampSchedule({
    required this.campaignId,
    required this.campaignName,
    required this.fromDate,
    required this.toDate,
    required this.status,
    required this.videoType,
    required this.urlYoutube,
    required this.urlUsp,
    required this.daysOfWeek,
    required this.deleted,
    required this.customerId,
    required this.fromTime,
    required this.toTime,
    required this.videoDuration,
  });

  factory CampSchedule.fromJson(Map<String, dynamic> json) {
    return CampSchedule(
      campaignId: json['campaign_id'],
      campaignName: json['campaign_name'],
      fromDate: json['from_date'],
      toDate: json['to_date'],
      status: json['status'],
      videoType: json['video_type'],
      urlYoutube: json['url_youtobe'],
      urlUsp: json['url_usp'],
      daysOfWeek: json['days_of_week'],
      deleted: json['deleted'] ?? '',
      customerId: json['customer_id'],
      fromTime: json['from_time'],
      toTime: json['to_time'],
      videoDuration: json['video_duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'campaign_id': campaignId,
      'campaign_name': campaignName,
      'from_date': fromDate,
      'to_date': toDate,
      'status': status,
      'video_type': videoType,
      'url_youtobe': urlYoutube,
      'url_usp': urlUsp,
      'days_of_week': daysOfWeek,
      'deleted': deleted,
      'customer_id': customerId,
      'from_time': fromTime,
      'to_time': toTime,
      'video_duration': videoDuration,
    };
  }
}
