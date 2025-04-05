import 'dart:convert';
import 'package:first_app/PlatformClient/config.dart';
import 'package:first_app/data/models/user_profile.dart';
import 'package:http/http.dart' as http;

class UsProfileRepository {
  String get baseUrl => '${Config.baseUrl}api/UserProfile';
  Future<UserProfile> fetchUserProfile(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/$userId/profile'));

    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  Future<UserProfile> fetchOtherUserProfile(int viewerId, int targetUserId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/view/$targetUserId?viewerId=$viewerId'),
    );
    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load other user profile');
    }
  }
}
