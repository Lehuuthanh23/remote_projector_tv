class SignUpRequestModel {
  final String name;
  final String email;
  final String phone;
  final String password;

  SignUpRequestModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  factory SignUpRequestModel.fromJson(Map<String, dynamic> json) {
    return SignUpRequestModel(
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    };
    return data;
  }
}
