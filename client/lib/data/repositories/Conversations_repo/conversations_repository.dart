import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/models/conversation.dart';

import '../../api/api_client.dart';

class ConversationRepo {
  var api_client = ApiClient();
  Future<List<Conversation>> getConversations(int userId) async {
  try {
    var response = await api_client.get('/api/Conversation/get_conversations/$userId');

    // In ra response để debug
    print("Full response: $response");

    // Kiểm tra và lấy danh sách từ `$values`
    if (response is Map<String, dynamic>) {
      var values = response[r'$values']; // Dùng raw string để tránh escape
      if (values is List) {
        return values
            .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        print("`$values` is not a List");
      }
    }

    return [];
  } catch (e, stack) {
    print('Lỗi khi tải cuộc trò chuyện: $e');
    print(stack);
    throw Exception('Failed to fetch conversations');
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
}
