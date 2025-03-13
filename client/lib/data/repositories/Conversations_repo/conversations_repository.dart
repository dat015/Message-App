import 'package:first_app/data/models/conversation.dart';

import '../../api/api_client.dart';

class ConversationRepo{
  var api_client = ApiClient();
  Future<List<Conversation>> getConversations(int userId) async {
    try{
        var response = await api_client.get('/api/Conversation/get_conversations/$userId');
        if(response is List){
          return response.map((json) => Conversation.fromJson(json)).toList();
        }
        return [];
    }catch (e) {
      throw Exception('Failed to fetch conversations');
    }
  }

  Future<Conversation> getConversation(int conversationId) async {
    try {
      var response = await api_client.get('/api/Conversation/get_first_conversation/$conversationId');
      if (response is Map<String, dynamic>) {
        return Conversation.fromJson(response);
      }
      throw Exception('Failed to fetch conversation');
    } catch (e) {
      throw Exception('Failed to fetch conversation');
    }

  }
}