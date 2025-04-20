import 'dart:convert';

import 'package:first_app/data/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user.dart';

class UserRepo {
  var api_client = ApiClient();
  Future<User> getUser(int userId) async {
    try {
      var response = await api_client.get('/api/User/getUser/$userId');
      if (response is Map<String, dynamic>) {
        return User.fromJson(response);
      }
      throw Exception('Failed to fetch user');
    } catch (e) {
      throw Exception('Failed to fetch user');
    }
  }

  Future<User?> GetUserFromApp() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson != null) {
      final Map<String, dynamic> userMap = jsonDecode(userJson);
      return User.fromJson(userMap); // Nếu bạn có class User.fromJson
    }

    return null;
  }
}
