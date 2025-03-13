  import 'package:first_app/data/api/api_client.dart';
  import 'package:first_app/data/models/messages.dart';

import '../Chat/websocket_service.dart';


  class MessageRepo{
    var api_client = ApiClient();
    Future<List<Message>> getMessages(int conversationId) async {
      try{
        var response = await api_client.get('/api/Message/getMessages/$conversationId');
        if(response is List){
          return response.map((json) => Message.fromJson(json)).toList();
        }
        return [];
      }catch(e){
        throw Exception('Failed to fetch messages');
      }
    }

    Future<void> sendMessage(Message message) async {

      try{
        final response = await api_client.post('/api/Message/sendMessage', data: message.toJson());
      }catch(e){
        throw Exception('Failed to send message');
      }
    }
  }