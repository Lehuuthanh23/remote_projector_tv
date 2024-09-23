class AppInfo {
  AppInfo._();

  static const userAndroidAppInfo = BaseInfo(
    version: 'TV1.0.0.1',
    buildDate: '30/08/2024 17:30',
  );
  static const userIOSAppInfo = BaseInfo(
    version: 'TV1.0.0.1',
    buildDate: '30/08/2024 15:00',
  );
}

class BaseInfo {
  final String version;
  final String buildDate;

  const BaseInfo({
    required this.version,
    required this.buildDate,
  });
}
