class Notify {
  String title;
  String descript;
  String detail;
  String picture;

  Notify({
    required this.title,
    required this.descript,
    required this.detail,
    required this.picture,
  });

  // fromJson method to create a Notification object from a map
  factory Notify.fromJson(Map<String, dynamic> json) {
    return Notify(
      title: json['title'],
      descript: json['descript'],
      detail: json['detail'],
      picture: json['picture'],
    );
  }

  // toJson method to convert a Notification object to a map
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'descript': descript,
      'detail': detail,
      'picture': picture,
    };
  }
}
