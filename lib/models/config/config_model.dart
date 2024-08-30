class ConfigModel {
  final String? companyName;
  final String? companyAddress;
  final String? hotline;
  final String? representative;
  final String? email;
  final String? taxCode;
  final String? apiServer;
  final String? guideLink;
  final int? activeCode;
  final String? appTVBoxVersion;
  final String? appTVBoxBuildDate;
  final String? appTVBoxUpdateUrl;
  const ConfigModel({
    this.companyName,
    this.companyAddress,
    this.hotline,
    this.representative,
    this.email,
    this.taxCode,
    this.apiServer,
    this.guideLink,
    this.activeCode,
    this.appTVBoxVersion,
    this.appTVBoxBuildDate,
    this.appTVBoxUpdateUrl,
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
      appTVBoxVersion: json['APPTVBOX_VERSION'],
      appTVBoxBuildDate: json['APPTVBOX_BUILD_DATE'],
      appTVBoxUpdateUrl: json['APPTVBOX_UPDATE_URL'],
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
      'APPTVBOX_VERSION': appTVBoxVersion,
      'APPTVBOX_BUILD_DATE': appTVBoxBuildDate,
      'APPTVBOX_UPDATE_URL': appTVBoxUpdateUrl,
    };
  }
}
