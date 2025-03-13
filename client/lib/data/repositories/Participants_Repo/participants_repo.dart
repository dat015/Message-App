import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/models/participants.dart';

class ParticipantsRepo{
  var api_client = ApiClient();
  Future<List<Participants>> getParticipants(int conversationId) async {
    try{
      var response = await api_client.get('/api/Participant/get_participants/$conversationId');
      if(response is List){
        return response.map((json) => Participants.fromJson(json)).toList();
      }
      return [];
    } catch(e){
      throw Exception('Failed to fetch participants');
    }
  }
}

