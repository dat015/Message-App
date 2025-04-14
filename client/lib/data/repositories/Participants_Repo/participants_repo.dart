import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/models/participants.dart';

class ParticipantsRepo {
  var api_client = ApiClient();
  Future<List<Participants>> getParticipants(int conversationId) async {
    try {
      final response = await api_client.get(
        '/api/Participant/get_participants/$conversationId',
      );
      print('Raw response: $response'); // Log để kiểm tra dữ liệu thô

      // Kiểm tra nếu response là Map
      if (response is Map<String, dynamic>) {
        // Lấy trường participants
        final participantsData = response['participants'];
        if (participantsData == null) {
          print('No participants data found in response');
          return [];
        }

        // Kiểm tra kiểu của participantsData
        if (participantsData is List) {
          // Nếu participants là danh sách trực tiếp
          return participantsData
              .map(
                (json) => Participants.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        } else if (participantsData is Map<String, dynamic>) {
          // Nếu participants là Map, kiểm tra trường 'values' hoặc '$values'
          final participantsList =
              participantsData['values'] ??
              participantsData['\$values'] ??
              participantsData['items'] ??
              [];
          if (participantsList is List) {
            return participantsList
                .map(
                  (json) => Participants.fromJson(json as Map<String, dynamic>),
                )
                .toList();
          }
        }
      } else if (response is List) {
        // Nếu response là danh sách trực tiếp
        return response
            .map((json) => Participants.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      print(
        'Invalid participants data format for conversation $conversationId',
      );
      return [];
    } catch (e, stackTrace) {
      print('Error fetching participants for conversation $conversationId: $e');
      print('StackTrace: $stackTrace');
      throw Exception('Failed to fetch participants: $e');
    }
  }

  Future<Participants> updateNickname(
    int currentUserId,
    int conversationId,
    String newNickname,
  ) async {
    try {
      print('currentUserId: $currentUserId');
      print('conversationId: $conversationId');
      print('newNickname: $newNickname');
      var response = await api_client.put(
        '/api/Participant/update_nickname/$currentUserId/$conversationId',
        data: jsonEncode({'nickname': newNickname}),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response is Map<String, dynamic>) {
        return Participants.fromJson(response);
      }
      throw Exception('Failed to update nickname');
    } catch (e) {
      throw Exception('Failed to update nickname');
    }
  }

  Future<Participants> leaveGroup(int conversationId, int currentUserId) async {
    try {
      var response = await api_client.delete(
        '/api/Participant/leave_group/$conversationId/$currentUserId',
      );
      if (response is Map<String, dynamic>) {
        return Participants.fromJson(response);
      }
      throw Exception('Failed to leave group');
    } catch (e) {
      throw Exception('Failed to leave group');
    }
  }

  Future<Participants> addMember(int conversationId, int userId) async {
    try {
      var response = await api_client.post(
        '/api/Participant/add_member/$conversationId/$userId',
      );
      if (response is Map<String, dynamic>) {
        return Participants.fromJson(response);
      }
      throw Exception('Failed to add member');
    } catch (e) {
      throw Exception('Failed to add member');
    }
  }
}
