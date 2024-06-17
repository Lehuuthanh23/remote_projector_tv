import 'dart:convert';

class User {
  String? customerId;
  String? customerName;
  String? address;
  String? phoneNumber;
  String? email;
  String? dateOfBirth;
  String? sex;
  String? chuTk;
  String? stk;
  String? nganhang;
  String? chinhanh;
  String? password;
  String? customerToken;
  User({
    this.customerId,
    this.customerName,
    this.address,
    this.phoneNumber,
    this.email,
    this.dateOfBirth,
    this.sex,
    this.chuTk,
    this.stk,
    this.nganhang,
    this.chinhanh,
    this.password,
    this.customerToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      address: json['address'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      dateOfBirth: json['date_of_birth'],
      sex: json['sex'],
      chuTk: json['chu_tk'],
      stk: json['stk'],
      nganhang: json['nganhang'],
      chinhanh: json['chinhanh'],
      password: json['password'],
      customerToken: json["customer_token"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'address': address,
      'phone_number': phoneNumber,
      'email': email,
      'date_of_birth': dateOfBirth,
      'sex': sex,
      'chu_tk': chuTk,
      'stk': stk,
      'nganhang': nganhang,
      'chinhanh': chinhanh,
      'password': password,
      'customer_token': customerToken,
    };
  }
}
