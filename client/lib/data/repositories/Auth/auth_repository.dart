import '../../dto/login_response.dart';
import '../../dto/register_dto.dart';
import '../../models/user.dart';
import '../../api/api_client.dart';


abstract class AuthRepository {
  Future<LoginResponse> login(String email, String password);
  Future<LoginResponse> register(RegisterDTO dto);
}