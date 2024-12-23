class Dir {
  int? dirId;
  String? dirName;
  int? customerId;
  String? dirType;
  int? createdBy;
  String? createdDate;
  String? lastModifyBy;
  String? lastModifyDate;
  String? deleted;
  bool? isOwner;

  Dir({
    this.dirId,
    this.dirName,
    this.customerId,
    this.dirType,
    this.createdBy,
    this.createdDate,
    this.lastModifyBy,
    this.lastModifyDate,
    this.deleted,
    this.isOwner = false,
  });

  factory Dir.fromJson(Map<String, dynamic> json) {
    return Dir(
      dirId: int.parse(json['id_dir']),
      dirName: json['name_dir'],
      customerId: int.parse(json['customer_id']),
      dirType: json['type_dir'],
      createdBy: int.parse(json['created_by']),
      createdDate: json['created_date'],
      lastModifyBy: json['last_MDF_by'],
      lastModifyDate: json['last_MDF_date'],
      deleted: json['deleted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_dir': dirId,
      'name_dir': dirName,
      'customer_id': customerId,
      'type_dir': dirType,
      'created_by': createdBy,
      'created_date': createdDate,
      'last_MDF_by': lastModifyBy,
      'last_MDF_date': lastModifyDate,
      'deleted': deleted,
    };
  }
}
