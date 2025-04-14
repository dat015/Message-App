import 'dart:convert';

import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/models/conversation.dart';
import 'dart:convert';

import '../../api/api_client.dart';

class ConversationRepo {
  var api_client = ApiClient();
  Future<List<Conversation>> getConversations(int userId) async {
  try {
    // Gửi yêu cầu API
    var response = await api_client.get('/api/Conversation/get_conversations/$userId');

    print("Response type: ${response.runtimeType}");
    print("Full response: $response");

    // Kiểm tra và lấy danh sách từ phản hồi
    List<dynamic> rawList;
    if (response is Map<String, dynamic> && response.containsKey(r'$values')) {
      rawList = response[r'$values'];
    } else {
      print("Unexpected response format: expected a Map with '\$values' key");
      return [];
    }

    // Chuyển đổi thành danh sách Conversation
    List<Conversation> conversations = rawList
        .map((item) {
          if (item is Map<String, dynamic>) {
            return Conversation.fromJson(item);
          } else {
            print("Invalid item in rawList: $item");
            return null;
          }
        })
        .where((item) => item != null)
        .cast<Conversation>()
        .toList();

    // Sắp xếp theo thời gian mới nhất
    conversations.sort((a, b) {
      DateTime timeA = a.lastMessageTime ?? a.createdAt;
      DateTime timeB = b.lastMessageTime ?? b.createdAt;
      return timeB.compareTo(timeA);
    });

    return conversations;
  } catch (e) {
    print("Error fetching conversations: $e");
    return [];
  }
}

  Future<Conversation> updateConversationName(
    int conversationId,
    String newName,
  ) async {
    try {
      var response = await api_client.put(
        '/api/Conversation/update_conversation_name/$conversationId',
        data: jsonEncode(newName), // gửi đúng JSON string
        headers: {'Content-Type': 'application/json'},
      );

      if (response is Map<String, dynamic>) {
        return Conversation.fromJson(response);
      }
      throw Exception('Failed to update conversation name');
    } catch (e) {
      throw Exception('Failed to update conversation name');
    }
  }

  Future<Conversation> getConversation(int conversationId) async {
    try {
      var response = await api_client.get(
        '/api/Conversation/get_first_conversation/$conversationId',
      );
      if (response is Map<String, dynamic>) {
        return Conversation.fromJson(response);
      }
      throw Exception('Failed to fetch conversation');
    } catch (e) {
      throw Exception('Failed to fetch conversation');
    }
  }

  Future<void> deleteConversation(int conversationId) async {
    try {
      var response = await api_client.delete(
        '/api/Conversation/delete_conversation/$conversationId',
      );
      if (response.statusCode == 200) {
        return;
      }
      throw Exception('Failed to delete conversation');
    } catch (e) {
      throw Exception('Failed to delete conversation');
    }
  }
}
