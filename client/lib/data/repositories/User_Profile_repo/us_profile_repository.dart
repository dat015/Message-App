import 'dart:convert';
import 'dart:io';
import 'package:first_app/PlatformClient/config.dart';
import 'package:first_app/data/models/user_profile.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class UsProfileRepository {
  String get baseUrl => '${Config.baseUrl}api/UserProfile';

  Future<UserProfile> fetchUserProfile(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$userId/profile'));

      if (response.statusCode == 200) {
        return UserProfile.fromJson(jsonDecode(response.body));
      }
      throw Exception('Tải hồ sơ người dùng thất bại.');
    } catch (e) {
      throw Exception('Tải hồ sơ người dùng thất bại: $e');
    }
  }

  Future<UserProfile> fetchOtherUserProfile(
    int viewerId,
    int targetUserId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/view/$targetUserId?viewerId=$viewerId'),
      );
      if (response.statusCode == 200) {
        return UserProfile.fromJson(jsonDecode(response.body));
      }
      throw Exception('Tải hồ sơ người dùng thất bại.');
    } catch (e) {
      throw Exception('Tải hồ sơ người dùng thất bại: $e');
    }
  }

  Future<void> updateUserProfile(UserProfile user) async {
    try {
      var body = jsonEncode(user.toMap());
      print('Request body: $body');
      final response = await http.put(
        Uri.parse('$baseUrl/update/profile/${user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toMap()),
      );

      if (response.statusCode == 200) {
        return;
      }
      throw Exception('Tải hồ sơ người dùng thất bại');
    } catch (e) {
      throw Exception('Tải hồ sơ người dùng thất bại: $e');
    }
  }

  Future<String> uploadImage(File image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          image.path,
          filename: basename(image.path),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('Upload successful: ${jsonData['url']}');
        return jsonData['url']; // Giả sử API trả về { "url": "http://..." }
      } else {
        print('Upload failed: ${response.statusCode} - ${response.body}');
        throw Exception(
          'Failed to upload image: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error during image upload: $e');
      throw Exception('Error uploading image: $e');
    }
  }
}
