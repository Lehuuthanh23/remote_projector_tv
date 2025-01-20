class AppInfo {
  AppInfo._();

  static const userAndroidAppInfo = BaseInfo(
    version: 'TV1.0.0.1',
    buildDate: '17/01/2025 17:30',
  );
  static const userIOSAppInfo = BaseInfo(
    version: 'TV1.0.0.1',
    buildDate: '17/01/2025 17:30',
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
