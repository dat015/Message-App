import '../models/user.dart';

class LoginResponse {
  User? user;
  String? token;
  String? message_response;

  LoginResponse({
    this.message_response,
    this.token,
    this.user,
  });
// parse từ json
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      token: json['token'] as String?,
      message_response: json['message_response'] as String?,
    );
  }
}