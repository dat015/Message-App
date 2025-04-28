import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/repositories/Auth/auth_repository.dart';
import 'package:first_app/data/repositories/Auth/auth_repository_implement.dart';
import 'package:first_app/features/auth/presentation/screens/otps_form.dart';
import 'package:flutter/material.dart';
import 'package:first_app/PlatformClient/config.dart';

Future<void> sendOTPToServer(
  BuildContext context,
  String email, {
  bool navigate = true,
  required bool isForRegistration,
}) async {
  final AuthRepository _authRepository = AuthRepositoryImpl(
    ApiClient(),
  ); // Sử dụng Config.baseUrl tự động
  try {
    var result = isForRegistration
        ? await _authRepository.sendOtpForRegistration(email)
        : await _authRepository.forgetPass(email);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          navigate ? 'OTP sent successfully!' : 'OTP resent successfully!',
        ),
      ),
    );
    if (navigate) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Otp(email: email, isForRegistration: isForRegistration,)),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Failed to send OTP: $e')));
  }
}
