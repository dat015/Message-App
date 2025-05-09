import 'package:first_app/data/api/api_client.dart';

import '../../models/user.dart';

class UserRepo {
  var api_client = ApiClient();
  Future<User> getUser(int userId) async {
    try {
      var response = await api_client.get('/api/User/getUser/$userId');
      if (response is Map<String, dynamic>) {
        return User.fromJson(response);
      }
      throw Exception('Không thể lấy thông tin người dùng');
    } catch (e) {
      throw Exception('Tải hồ sơ người dùng thất bại: $e');
    }
  }
}
