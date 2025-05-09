import 'dart:convert';
import 'package:first_app/PlatformClient/config.dart';
import 'package:http/http.dart' as http;

class SettingRepo {
  String get baseUrl => '${Config.baseUrl}api';

  Future<bool> sendOtp(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/setting/otp/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) return true;
    throw Exception('Gửi OTP thất bại: ${response.body}');
  }

  Future<bool> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/setting/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otpCode': otp}),
    );

    if (response.statusCode == 200) return true;
    throw Exception('Xác minh OTP thất bại: ${response.body}');
  }

  Future<bool> changeEmail(String currentEmail, String newEmail) async {
    final response = await http.post(
      Uri.parse('$baseUrl/setting/change-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'currentEmail': currentEmail, 'newEmail': newEmail}),
    );

    if (response.statusCode == 200) return true;
    throw Exception('Đổi email thất bại: ${response.body}');
  }

  Future<bool> changePassword(String currentPassword, String newPassword, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/setting/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'currentPass': currentPassword,
        'newPass': newPassword,
        'email': email,
      }),
    );

    if (response.statusCode == 200) return true;
    throw Exception('Đổi mật khẩu thất bại: ${response.body}');
  }
}