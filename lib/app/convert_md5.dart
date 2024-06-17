import 'dart:convert';
import 'dart:core';
import 'package:crypto/crypto.dart';

String convertToMD5(String input) {
  // Chuyển đổi chuỗi thành bytes
  var bytes = utf8.encode(input);

  // Mã hóa bytes thành MD5
  var digest = md5.convert(bytes);

  // Trả về chuỗi MD5 dưới dạng hex
  return digest.toString();
}
