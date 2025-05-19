import 'dart:convert';

import 'package:first_app/data/dto/ConversationDto%20.dart';
import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/models/conversation.dart';
import 'dart:convert';

import '../../api/api_client.dart';

class ConversationRepo {
  var api_client = ApiClient();

  Future<Conversation> createGroup(
    int userId,
    String groupName,
    List<int> userIds,
  ) async {
    try {
      // Chuyển đổi danh sách userIds thành JSON
      var groupDto = jsonEncode({
        'userId': userId,
        'groupName': groupName,
        'userIds': userIds,
      });

      // Gửi yêu cầu API
      var response = await api_client.post(
        '/api/Conversation/create_group',
        data: groupDto,
      );
      // Kiểm tra nếu phản hồi có dữ liệu và là kiểu Map
      if (response is Map<String, dynamic>) {
        print('Create group response: $response');
        return Conversation.fromJson(
          response,
        ); // Truyền response trực tiếp mà không cần lấy data
      }
      // Kiểm tra dữ liệu trả về là null hoặc không phải Map hợp lệ
      throw Exception('Invalid response format: $response');
    } catch (e) {
      // Xử lý các lỗi trong quá trình gọi API
      print('Error creating group: $e');
      throw Exception('Failed to create group: $e');
    }
  }

  Future<ConversationDto> openConversation(int user1, int user2) async {
    try {
      final response = await api_client.get(
        '/api/Conversation/open_conversation/$user1/$user2',
      );

      // Kiểm tra nếu phản hồi có dữ liệu và là kiểu Map
      if (response is Map<String, dynamic>) {
        print('Open conversation response: $response');
        return ConversationDto.fromJson(
          response,
        ); // Truyền response trực tiếp mà không cần lấy data
      }

      // Kiểm tra dữ liệu trả về là null hoặc không phải Map hợp lệ
      throw Exception('Invalid response format: $response');
    } catch (e) {
      // Xử lý các lỗi trong quá trình gọi API
      print('Error opening conversation: $e');
      throw Exception('Failed to open conversation: $e');
    }
  }

  Future<List<Conversation>> getConversations(int userId) async {
    try {
      // Gửi yêu cầu API
      var response = await api_client.get(
        '/api/Conversation/get_conversations/$userId',
      );

      print("Response type: ${response.runtimeType}");
      print("Full response: $response");

      // Kiểm tra và lấy danh sách từ phản hồi
      List<dynamic> rawList;
      if (response is Map<String, dynamic> &&
          response.containsKey(r'$values')) {
        rawList = response[r'$values'];
      } else {
        print("Unexpected response format: expected a Map with '\$values' key");
        return [];
      }

      // Chuyển đổi thành danh sách Conversation
      List<Conversation> conversations =
          rawList
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

  Future<Conversation?> getConversationDto(int userId, int conversationId) async {
    try {
      // Gửi yêu cầu API để lấy một conversation
      var response = await api_client.get(
        '/api/Conversation/get_conversationDto/$userId/$conversationId',
      );

      print("Response type: ${response.runtimeType}");
      print("Full response: $response");

      // Kiểm tra phản hồi và chuyển đổi thành Conversation
      if (response is Map<String, dynamic>) {
        return Conversation.fromJson(response);
      } else {
        print("Unexpected response format: expected a Map");
        return null;
      }
    } catch (e) {
      print("Error fetching conversation: $e");
      return null;
    }
  }

  void updateGroupImage(int conversationId, String image) async {
    try {
      var response = await api_client.put(
        '/api/Conversation/update_conversation_image/$conversationId',
        data: jsonEncode(image), // gửi đúng JSON string
        headers: {'Content-Type': 'application/json'},
      );

      if (response is Map<String, dynamic>) {
        return;
      }
      throw Exception('Failed to update group image');
    } catch (e) {
      throw Exception('Failed to update group image');
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
