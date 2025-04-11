import 'dart:convert';
import 'package:http/http.dart' as http;

class JamendoService {
  static const String clientId = 'd4dccdb7'; 
  static const String baseUrl = 'https://api.jamendo.com/v3.0';

  Future<List<Map<String, dynamic>>> fetchTracks({
    int limit = 10,
    String format = 'mp32',
    String? search,
  }) async {
    try {
      final query = search != null && search.isNotEmpty ? '&search=$search' : '';
      final response = await http.get(
        Uri.parse(
          '$baseUrl/tracks/?client_id=$clientId&format=json&limit=$limit&audioformat=$format&license_cc=cc$query',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['results']);
      } else {
        throw Exception('Không thể tải danh sách nhạc: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi gọi API Jamendo: $e');
      throw Exception('Lỗi khi tải nhạc: $e');
    }
  }
}