import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/repositories/Auth/auth_repository.dart';
import 'package:first_app/data/repositories/Auth/auth_repository_implement.dart';
import 'package:first_app/features/auth/presentation/screens/otps_form.dart';
import 'package:flutter/material.dart';

Future<void> sendOTPToServer(
    BuildContext context, String email, {bool navigate = true}) async {
  final AuthRepository _authRepository =
      AuthRepositoryImpl(ApiClient(baseUrl: 'http://localhost:5053/'));
  try {
    var result = await _authRepository.forgetPass(email);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(navigate ? 'OTP sent successfully!' : 'OTP resent successfully!')),
    );
    if (navigate) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Otp(email: email),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to send OTP: $e')),
    );
  }
}