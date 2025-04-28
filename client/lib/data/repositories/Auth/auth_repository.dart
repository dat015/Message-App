import 'package:first_app/data/dto/otp_response.dart';

import '../../dto/login_response.dart';
import '../../dto/register_dto.dart';
import '../../models/user.dart';
import '../../api/api_client.dart';

abstract class AuthRepository {
  Future<LoginResponse> login(String email, String password);
  Future<LoginResponse> register(RegisterDTO dto);
  Future<OTPsResponse> forgetPass(String email);
  Future<OTPsResponse> sendOtpForRegistration(String email);
  Future<OTPsResponse> verifyOtp(String email, String otp);
  Future<OTPsResponse> verifyOtpRegister(String email, String otp);
  Future<Map<String, dynamic>> changePassword(String email, String newPassword);
}
