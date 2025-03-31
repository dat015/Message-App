import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/models/messages.dart';

import '../Chat/websocket_service.dart';

class MessageRepo {
  var api_client = ApiClient();
  Future<List<Message>> getMessages(int conversationId) async {
    try {
      var response = await api_client.get(
        '/api/Message/getMessages/$conversationId',
      );

      // Debug response
      print("Response: $response"); // Kiểm tra nội dung của response

      List<Message> messages = [];

      if (response is List) {
        messages = response.map((json) => Message.fromJson(json)).toList();
      } else if (response is Map<String, dynamic> &&
          response.containsKey("data")) {
        // Nếu API trả về dạng {"data": [...]}, lấy danh sách từ key "data"
        var data = response["data"];
        if (data is List) {
          messages = data.map((json) => Message.fromJson(json)).toList();
        }
      }

      // Sắp xếp tin nhắn theo thời gian (theo trường created_at)
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return messages;
    } catch (e) {
      print("Error fetching messages: $e"); // In lỗi chi tiết
      throw Exception('Failed to fetch messages');
    }
  }

  Future<void> sendMessage(Message message) async {
    try {
      final response = await api_client.post(
        '/api/Message/sendMessage',
        data: message.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to send message');
    }
  }
}
