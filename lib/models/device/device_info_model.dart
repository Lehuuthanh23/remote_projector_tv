class DeviceInfoModel {
  final String model;
  final String manufacturer;
  final String osVersion;
  final String deviceName;
  final String platform;
  final String? serialNumber;
  final String androidId;
  final String uuid;

  DeviceInfoModel({
    required this.model,
    required this.manufacturer,
    required this.osVersion,
    required this.deviceName,
    required this.platform,
    this.serialNumber,
    required this.androidId,
    required this.uuid,
  });

  factory DeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return DeviceInfoModel(
      model: json['model'],
      manufacturer: json['manufacturer'],
      osVersion: json['osVersion'],
      deviceName: json['deviceName'],
      platform: json['platform'],
      serialNumber: json['serialNumber'],
      androidId: json['androidId'],
      uuid: json['uuid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'manufacturer': manufacturer,
      'osVersion': osVersion,
      'deviceName': deviceName,
      'platform': platform,
      'serialNumber': serialNumber,
      'androidId': androidId,
      'uuid': uuid,
    };
  }

  @override
  String toString() {
    return 'DeviceInfoModel(model: $model, manufacturer: $manufacturer, osVersion: $osVersion, deviceName: $deviceName, platform: $platform, serialNumber: $serialNumber, androidId: $androidId, uuid: $uuid)';
  }
}
