class Device {
  String computerId;
  String computerName;
  String serialComputer;
  String ipAddress;
  String status;
  String provinces;
  String district;
  String wards;
  String centerId;
  String location;
  String activedDate;
  String createdDate;
  String ultraviewPW;
  String ultraviewID;
  String customerId;
  String type;
  String idDir;
  String? nameDir;
  String timeEnd;
  int turnOn;
  int turnOff;
  String createdBy;
  String lastMDFBy;
  String lastMDFDate;
  String user;
  String pass;
  String deleted;
  int isCheckOnProjector;
  int isCheckOffProjector;

  Device({
    required this.computerId,
    required this.computerName,
    required this.serialComputer,
    required this.ipAddress,
    required this.status,
    required this.provinces,
    required this.district,
    required this.wards,
    required this.centerId,
    required this.location,
    required this.activedDate,
    required this.createdDate,
    required this.ultraviewPW,
    required this.ultraviewID,
    required this.customerId,
    required this.type,
    required this.idDir,
    this.nameDir,
    required this.timeEnd,
    required this.turnOn,
    required this.turnOff,
    required this.createdBy,
    required this.lastMDFBy,
    required this.lastMDFDate,
    required this.user,
    required this.pass,
    required this.deleted,
    required this.isCheckOnProjector,
    required this.isCheckOffProjector,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      computerId: json['computer_id'],
      computerName: json['computer_name'],
      serialComputer: json['seri_computer'],
      ipAddress: json['ip_address'],
      status: json['status'] == '' ? '0' : json['status'],
      provinces: json['provinces'],
      district: json['district'],
      wards: json['wards'],
      centerId: json['center_id'],
      location: json['location'],
      activedDate: json['actived_date'],
      createdDate: json['created_date'],
      ultraviewPW: json['ultraviewPW'],
      ultraviewID: json['ultraviewID'],
      customerId: json['customer_id'],
      type: json['type'],
      idDir: json['id_dir'],
      nameDir: json['name_dir'],
      timeEnd: json['time_end'],
      turnOn: int.parse(json['turn_on']),
      turnOff: int.parse(json['turn_off']),
      createdBy: json['created_by'],
      lastMDFBy: json['last_MDF_by'],
      lastMDFDate: json['last_MDF_date'],
      user: json['user'],
      pass: json['pass'],
      deleted: json['deleted'],
      isCheckOnProjector: int.parse(json['isCheckOnProjector']),
      isCheckOffProjector: int.parse(json['isCheckOffProjector']),
    );
  }
}
