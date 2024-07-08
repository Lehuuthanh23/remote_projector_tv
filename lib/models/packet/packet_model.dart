class PacketModel {
  String? monthQty;
  String paidId;
  String packetCode;
  String regNumber;
  String namePacket;
  String price;
  String? expireDate;
  String picture;
  String description;
  String detail;
  String customerId;
  String? pay;
  String createdDate;
  String createdBy;
  String lastMDFBy;
  String lastMDFDate;
  String deleted;
  String registerDate;
  String? paymentDate;
  String? validDate;
  String? typePay;
  String packetId;

  PacketModel({
    this.monthQty,
    required this.paidId,
    required this.packetCode,
    required this.regNumber,
    required this.namePacket,
    required this.price,
    this.expireDate,
    required this.picture,
    required this.description,
    required this.detail,
    required this.customerId,
    this.pay,
    required this.createdDate,
    required this.createdBy,
    required this.lastMDFBy,
    required this.lastMDFDate,
    required this.deleted,
    required this.registerDate,
    this.paymentDate,
    this.validDate,
    this.typePay,
    required this.packetId,
  });

  factory PacketModel.fromJson(Map<String, dynamic> json) {
    return PacketModel(
      monthQty: json['month_qty'],
      paidId: json['paid_id'],
      packetCode: json['packet_code'],
      regNumber: json['reg_number'],
      namePacket: json['name_packet'],
      price: json['price'],
      expireDate: json['expire_date'],
      picture: json['picture'],
      description: json['description'],
      detail: json['detail'],
      customerId: json['customer_id'],
      pay: json['pay'],
      createdDate: json['created_date'],
      createdBy: json['created_by'],
      lastMDFBy: json['last_MDF_by'],
      lastMDFDate: json['last_MDF_date'],
      deleted: json['deleted'],
      registerDate: json['register_date'],
      paymentDate: json['payment_date'],
      validDate: json['valid_date'],
      typePay: json['type_pay'],
      packetId: json['packet_id'],
    );
  }
}