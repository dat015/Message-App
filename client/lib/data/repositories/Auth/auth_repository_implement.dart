import 'package:dio/dio.dart';
import 'package:first_app/data/dto/otp_response.dart';
import 'package:first_app/data/dto/register_dto.dart';
import '../../api/api_client.dart';
import '../../dto/login_response.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;

  AuthRepositoryImpl(this._apiClient);

  @override
  Future<LoginResponse> login(String email, String password) async {
    try {
      print('Attempting login with email: $email');
      final response = await _apiClient.post(
        '/api/Auth/login',
        data: {'email': email, 'password': password},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      print('Login response received: $response');
      return LoginResponse.fromJson(response);
    } catch (e) {
      print('Login error details: $e');
    throw Exception('Đăng nhập thất bại: $e');
    }
  }

  @override
  Future<LoginResponse> register(RegisterDTO dto) async {
    print(dto);
    try {
      final response = await _apiClient.post(
        '/api/Auth/register',
        data: dto.toJson(),
      );
      return LoginResponse.fromJson(response);
    } catch (e) {
      print('Register error: $e');
      throw Exception('Đăng ký thất bại: $e');
    }
  }

  @override
  Future<OTPsResponse> sendOtpForRegistration(String email) async {
    try {
      final response = await _apiClient.post(
        '/api/Auth/send-otp-registration',
        data: {'email': email},
      );
      if (response['OTPCode'] != "") {
        return OTPsResponse.fromJson(response);
      }
      throw Exception('OTP không được trả về từ máy chủ');
    } catch (e) {
      print('Send OTP for registration error: $e');
      throw Exception('Gửi OTP thất bại: $e');
    }
  }

  @override
  Future<OTPsResponse> forgetPass(String email) async {
    try {
      final response = await _apiClient.post(
        '/api/ForgetPassword/ForgetPass',
        data: {'email': email},
      );

      if (response['OTPCode'] != "") {
        return OTPsResponse.fromJson(response);
      } 
      throw Exception('Không có phản hồi từ máy chủ');
    } catch (e) {
      print('Forget password error: $e');
      throw Exception('Quên mật khẩu thất bại: $e');
    }
  }

  @override
  Future<OTPsResponse> verifyOtp(String email, String otp) async {
    if (email.isEmpty || otp.isEmpty) {
      throw Exception('Email hoặc mã OTP không được để trống');
    }

    try {
      final response = await _apiClient.post(
        '/api/ForgetPassword/verify-otp',
        data: {'email': email, 'OTPCode': otp},
      );
      return OTPsResponse.fromJson(response);
    } catch (e) {
      print('Verify OTP error: $e');
    throw Exception('Xác nhận mã OTP thất bại: $e');
    }
  }

  @override
  Future<OTPsResponse> verifyOtpRegister(String email, String otp) async {
    if (email.isEmpty || otp.isEmpty) {
      throw Exception('Email hoặc mã OTP không được để trống');
    }

    try {
      final response = await _apiClient.post(
        '/api/Auth/verify-otp',
        data: {'email': email, 'OTPCode': otp},
      );
      return OTPsResponse.fromJson(response);
    } catch (e) {
      print('Verify OTP error: $e');
    throw Exception('Xác nhận mã OTP thất bại: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> changePassword(
    String email,
    String newPassword,
  ) async {
    try {
      final response = await _apiClient.post(
        '/api/ForgetPassword/ChangePassword',
        data: {'email': email, 'newPassword': newPassword},
      );
      return response;
    } catch (e) {
    throw Exception('Thay đổi mật khẩu thất bại: $e');
    }
  }
}
