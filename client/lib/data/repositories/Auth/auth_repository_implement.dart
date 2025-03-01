import 'package:dio/dio.dart';
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
        data: {
          'email': email,
          'password': password,
        },
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
}