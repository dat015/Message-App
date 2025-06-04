import 'dart:convert';
import 'package:first_app/PlatformClient/config.dart';
import 'package:first_app/data/dto/friend_dto.dart';
import 'package:first_app/data/dto/friendrequest_withdetails.dart';
import 'package:first_app/data/models/friendsuggestion.dart';
import 'package:first_app/data/models/user.dart';
import 'package:first_app/data/api/api_client.dart';

class FriendsRepo {
  final ApiClient _apiClient = ApiClient();
  String get baseUrl => 'api/friends';


  Future<List<FriendRequestWithDetails>> getFriendRequests(int userId) async {
    try {
      final response = await _apiClient.get(
        '$baseUrl/requests/received/$userId',
      );
      final isSuccess =
          response['success'] == true ||
          response['success'] == "true" ||
          response['success'] == 1;

      if (isSuccess) {
        final requestsData = response['requests'];
        if (requestsData is Map<String, dynamic> &&
            requestsData.containsKey('\$values')) {
          final requests = requestsData['\$values'] as List<dynamic>;
          return requests
              .map((json) => FriendRequestWithDetails.fromJson(json))
              .toList();
        } else if (requestsData is List<dynamic>) {
          return requestsData
              .map((json) => FriendRequestWithDetails.fromJson(json))
              .toList();
        } else {
          throw Exception(
            'Invalid response format: requests is neither a list nor a map with \$values',
          );
        }
      } else {
        throw Exception(
          'Failed to load friend requests: ${response['message']}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load friend requests: $e');
    }
  }

  Future<List<FriendSuggestion>> getFriendSuggestions(int userId) async {
    try {
      final response = await _apiClient.get('$baseUrl/suggestions/$userId');
      final isSuccess =
          response['success'] == true ||
          response['success'] == "true" ||
          response['success'] == 1;

      if (isSuccess) {
        final suggestionsData = response['suggestions'];
        if (suggestionsData is Map<String, dynamic> &&
            suggestionsData.containsKey('\$values')) {
          final suggestions = suggestionsData['\$values'] as List<dynamic>;
          return suggestions
              .map((json) => FriendSuggestion.fromJson(json))
              .toList();
        } else if (suggestionsData is List<dynamic>) {
          return suggestionsData
              .map((json) => FriendSuggestion.fromJson(json))
              .toList();
        } else {
          throw Exception(
            'Invalid response format: suggestions is neither a list nor a map with \$values',
          );
        }
      } else {
        throw Exception('Failed to load suggestions: ${response['message']}');
      }
    } catch (e) {
      throw Exception('Failed to load suggestions: $e');
    }
  }

  Future<void> acceptFriendRequest(int requestId) async {
    try {
      await _apiClient.post(
        '$baseUrl/accept-request/$requestId',
        data: {'requestId': requestId},
      );
    } catch (e) {
      throw Exception('Failed to accept friend request: $e');
    }
  }

  Future<void> rejectFriendRequest(int requestId) async {
    try {
      await _apiClient.post(
        '$baseUrl/reject-request/$requestId',
        data: {'requestId': requestId},
      );
    } catch (e) {
      throw Exception('Failed to reject friend request: $e');
    }
  }

  Future<void> sendFriendRequest(
    int senderId,
    int receiverId,
    String username,
    String avatarUrl,
  ) async {
    try {
      await _apiClient.post(
        '$baseUrl/send-request',
        data: {
          'senderId': senderId,
          'receiverId': receiverId,
          'username': username,
          'status': 'Pending',
          'avatarUrl': avatarUrl,
        },
      );
    } catch (e) {
      throw Exception('Failed to send friend request: $e');
    }
  }

  Future<List<User>> getFriends(int userId) async {
    try {
      final response = await _apiClient.get('$baseUrl/list/$userId');
      bool isSuccess;
      if (response['success'] is bool) {
        isSuccess = response['success'] as bool;
      } else if (response['success'] is String) {
        isSuccess = response['success'].toLowerCase() == 'true';
      } else {
        throw Exception('Invalid success value: ${response['success']}');
      }

      if (isSuccess) {
        final friendsData = response['friends'];
        List<dynamic> friends;
        if (friendsData is Map<String, dynamic> &&
            friendsData.containsKey('\$values')) {
          friends = friendsData['\$values'] as List<dynamic>;
        } else if (friendsData is List<dynamic>) {
          friends = friendsData;
        } else {
          throw Exception(
            'Invalid response format: friends is neither a list nor a map with \$values',
          );
        }

        return friends.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load friends: ${response['message']}');
      }
    } catch (e) {
      print('Error in getFriends: $e');
      return [];
    }
  }

  Future<List<FriendDTO>> getFriendsDTO(int userId) async {
    try {
      final response = await _apiClient.get('$baseUrl/GetAllFriends/$userId');
      List<dynamic> friendsData = [];

      if (response is Map<String, dynamic>) {
        final dynamic successRaw = response['success'];
        final bool isSuccess =
            successRaw == true ||
            (successRaw is String && successRaw.toLowerCase() == 'true');

        if (!isSuccess) {
          throw Exception(
            'Không thể tải danh sách bạn bè: ${response['message'] ?? 'Không rõ lỗi'}',
          );
        }

        final dynamic friendsWrapper = response['friends'];
        if (friendsWrapper is Map<String, dynamic> &&
            friendsWrapper.containsKey(r'$values')) {
          final dynamic values = friendsWrapper[r'$values'];
          if (values is List<dynamic>) {
            friendsData = values;
          } else {
            throw Exception(
              'Giá trị $values không phải danh sách bạn bè hợp lệ',
            );
          }
        } else {
          throw Exception('Không tìm thấy trường trong friends');
        }
      } else if (response is List<dynamic>) {
        friendsData = response;
      } else {
        throw Exception('Phản hồi API không hợp lệ: $response');
      }

      return friendsData.map((json) => FriendDTO.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Không thể tải danh sách bạn bè: $e');
    }
  }

  Future<List<FriendRequestWithDetails>> getSentFriendRequests(
    int userId,
  ) async {
    try {
      final response = await _apiClient.get(
        '$baseUrl/get-sent-requests/$userId',
      );
      bool isSuccess;
      if (response['success'] is bool) {
        isSuccess = response['success'] as bool;
      } else if (response['success'] is String) {
        isSuccess = response['success'].toLowerCase() == 'true';
      } else {
        throw Exception('Invalid success value: ${response['success']}');
      }

      if (isSuccess) {
        final requestsData = response['sentRequests'];
        if (requestsData is Map<String, dynamic> &&
            requestsData.containsKey('\$values')) {
          final requests = requestsData['\$values'] as List<dynamic>;
          return requests
              .map((json) => FriendRequestWithDetails.fromJson(json))
              .toList();
        } else if (requestsData is List<dynamic>) {
          return requestsData
              .map((json) => FriendRequestWithDetails.fromJson(json))
              .toList();
        } else {
          throw Exception(
            'Invalid response format: sentRequests is neither a list nor a map with \$values',
          );
        }
      } else {
        throw Exception(
          'Failed to load sent friend requests: ${response['message']}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load sent friend requests: $e');
    }
  }

  Future<void> cancelFriendRequest(int senderId, int receiverId) async {
    try {
      await _apiClient.post(
        '$baseUrl/cancel-request',
        data: {'senderId': senderId, 'receiverId': receiverId},
      );
    } catch (e) {
      throw Exception('Failed to cancel friend request: $e');
    }
  }

  Future<void> unfriend(int userId, int friendId) async {
    try {
      await _apiClient.post(
        '$baseUrl/unfriend',
        data: {'userId': userId, 'friendId': friendId},
      );
    } catch (e) {
      throw Exception('Failed to unfriend: $e');
    }
  }
}
