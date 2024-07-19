class PacketModel {
  String? monthQty;
  String? paidId;
  String? packetCode;
  String? regNumber;
  String? namePacket;
  String? price;
  String? expireDate;
  String? picture;
  String? description;
  String? detail;
  String? customerId;
  String? pay;
  String? createdDate;
  String? createdBy;
  String? lastMDFBy;
  String? lastMDFDate;
  String? deleted;
  String? registerDate;
  String? paymentDate;
  String? validDate;
  String? typePay;
  String? packetId;

  PacketModel({
    this.monthQty,
    this.paidId,
    this.packetCode,
    this.regNumber,
    this.namePacket,
    this.price,
    this.expireDate,
    this.picture,
    this.description,
    this.detail,
    this.customerId,
    this.pay,
    this.createdDate,
    this.createdBy,
    this.lastMDFBy,
    this.lastMDFDate,
    this.deleted,
    this.registerDate,
    this.paymentDate,
    this.validDate,
    this.typePay,
    this.packetId,
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