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
      final response = await _apiClient.put(
        '/api/Auth/login', // Đảm bảo khớp với API login của bạn
        data: {'email': email, 'password': password},
      );
      return LoginResponse.fromJson(response);
    } catch (e) {
      print('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<LoginResponse> register(RegisterDTO dto) async {
    print(dto);
    try {
      final response = await _apiClient.post(
        '/api/Auth/register', // Sửa đường dẫn cho khớp API
        data: dto.toJson(),
      );
      return LoginResponse.fromJson(response);
    } catch (e) {
      print('Register error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  @override
 Future<OTPsResponse> forgetPass(String email) async {
  try {
    final response = await _apiClient.post(
      '/api/ForgetPassword/ForgetPass', // Đường dẫn API để gửi OTP
      data: {'email': email},
    );

    // Giả định response là Map<String, dynamic>
    // Kiểm tra thành công dựa trên trường trong JSON
    if (response['OTPCode'] != "") { // Hoặc dùng trường khác như 'success'
       return OTPsResponse.fromJson(response);
    } else {
      final errorMessage = response['message'] ?? 'Unknown error';
      throw Exception('Failed to send OTP: $errorMessage');
    }
  } catch (e) {
    print('Forget password error: $e');
    throw Exception('Failed to send OTP: $e');
  }
}

  @override
  Future<OTPsResponse> verifyOtp(String email, String otp) async {
    if (email.isEmpty || otp.isEmpty) {
      throw Exception('Email or OTP cannot be empty');
    }

    try {
      final response = await _apiClient.post(
        '/api/ForgetPassword/verify-otp',
        data: {'email': email, 'OTPCode': otp},
      );

      if (response.containsKey('errors')) {
        final errorMessage = response['errors']['OTPCode']?.join(', ') ?? 'Unknown error';
        throw Exception('Failed to verify OTP: $errorMessage');
      }

      return OTPsResponse.fromJson(response);
    } catch (e) {
      print('Verify OTP error: $e');
      throw Exception('Failed to verify OTP: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> changePassword(String email, String newPassword) async {
    try {
      final response = await _apiClient.post(
        '/api/ForgetPassword/ChangePassword',
        data: {
          'email': email,
          'newPassword': newPassword,
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }
}
