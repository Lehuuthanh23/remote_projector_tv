class ConfigModel {
  String? companyName;
  String? companyAddress;
  String? hotline;
  String? representative;
  String? email;
  String? taxCode;
  String? apiServer;
  String? guideLink;
  int? activeCode;

  ConfigModel({
    this.companyName,
    this.companyAddress,
    this.hotline,
    this.representative,
    this.email,
    this.taxCode,
    this.apiServer,
    this.guideLink,
    this.activeCode,
  });

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(
      companyName: json['COMPANY_NAME'],
      companyAddress: json['COMPANY_ADDRESS'],
      hotline: json['HOTLINE'],
      representative: json['REPRESENTATIVE'],
      email: json['EMAIL'],
      taxCode: json['TAX_CODE'],
      apiServer: json['API_SERVER'],
      guideLink: json['GUIDE_LINK'],
      activeCode: json['ACTIVE_FLAG'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'COMPANY_NAME': companyName,
      'COMPANY_ADDRESS': companyAddress,
      'HOTLINE': hotline,
      'REPRESENTATIVE': representative,
      'EMAIL': email,
      'TAX_CODE': taxCode,
      'API_SERVER': apiServer,
      'GUIDE_LINK': guideLink,
      'ACTIVE_FLAG': activeCode,
    };
  }
}
