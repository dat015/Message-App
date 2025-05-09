import 'dart:convert';
import 'package:first_app/PlatformClient/config.dart';
import 'package:first_app/data/dto/friend_dto.dart';
import 'package:first_app/data/dto/friendrequest_withdetails.dart';
import 'package:first_app/data/models/friendsuggestion.dart';
import 'package:first_app/data/models/user.dart';
import 'package:http/http.dart' as http;

class FriendsRepo {
  String get baseUrl => '${Config.baseUrl}api/friends';

  Future<List<FriendRequestWithDetails>> getFriendRequests(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/requests/received/$userId'),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final isSuccess =
          jsonResponse['success'] == true ||
          jsonResponse['success'] == "true" ||
          jsonResponse['success'] == 1;

      if (isSuccess) {
        final requests = jsonResponse['requests'] as List<dynamic>;
        return requests
            .map((json) => FriendRequestWithDetails.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Failed to load friend requests: ${jsonResponse['message']}',
        );
      }
    } else {
      throw Exception('Failed to load friend requests: ${response.statusCode}');
    }
  }

  Future<List<FriendSuggestion>> getFriendSuggestions(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/suggestions/$userId'));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final isSuccess =
          jsonResponse['success'] == true ||
          jsonResponse['success'] == "true" ||
          jsonResponse['success'] == 1;

      if (isSuccess) {
        final suggestions = jsonResponse['suggestions'] as List<dynamic>;
        return suggestions
            .map((json) => FriendSuggestion.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Failed to load suggestions: ${jsonResponse['message']}',
        );
      }
    } else {
      throw Exception('Failed to load suggestions: ${response.statusCode}');
    }
  }

  Future<void> acceptFriendRequest(int requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/accept-request/$requestId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'requestId': requestId}),
    );

    if (response.statusCode != 200) {
      final jsonResponse = jsonDecode(response.body);
      throw Exception(
        'Failed to accept friend request: ${jsonResponse['message']}',
      );
    }
  }

  Future<void> rejectFriendRequest(int requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reject-request/$requestId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'requestId': requestId}),
    );

    if (response.statusCode != 200) {
      final jsonResponse = jsonDecode(response.body);
      throw Exception(
        'Failed to reject friend request: ${jsonResponse['message']}',
      );
    }
  }

  Future<void> sendFriendRequest(
    int senderId,
    int receiverId,
    String username,
    String avatarUrl,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/send-request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'senderId': senderId,
        'receiverId': receiverId,
        'username': username,
        'status': 'Pending',
        'avatarUrl': avatarUrl,
      }),
    );

    if (response.statusCode != 200) {
      final jsonResponse = jsonDecode(response.body);
      throw Exception(
        'Failed to send friend request: ${jsonResponse['message']}',
      );
    }
  }

  Future<List<User>> getFriends(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/list/$userId'));
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      bool isSuccess;
      if (jsonResponse['success'] is bool) {
        isSuccess = jsonResponse['success'] as bool;
      } else if (jsonResponse['success'] is String) {
        isSuccess = jsonResponse['success'].toLowerCase() == 'true';
      } else {
        throw Exception('Invalid success value: ${jsonResponse['success']}');
      }

      if (isSuccess) {
        final friends = jsonResponse['friends'] as List<dynamic>;
        return friends.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load friends: ${jsonResponse['message']}');
      }
    } else {
      throw Exception('Failed to load friends: ${response.statusCode}');
    }
  }

  Future<List<FriendDTO>> getFriendsDTO(int userId) async {
  final url = '$baseUrl/GetAllFriends/$userId';
  final response = await http.get(Uri.parse(url));
  print('Request URL: $url');
  print('Response Status: ${response.statusCode}');

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    print('API Response: $jsonResponse');

    List<dynamic> friendsData = [];

    if (jsonResponse is Map<String, dynamic>) {
      // Xử lý trường hợp response có 'success' và 'friends'
      final dynamic successRaw = jsonResponse['success'];
      final bool isSuccess = successRaw == true ||
          (successRaw is String && successRaw.toLowerCase() == 'true');

      if (!isSuccess) {
        throw Exception(
          'Không thể tải danh sách bạn bè: ${jsonResponse['message'] ?? 'Không rõ lỗi'}',
        );
      }

      final dynamic friendsWrapper = jsonResponse['friends'];
      if (friendsWrapper is Map<String, dynamic> && friendsWrapper.containsKey(r'$values')) {
        final dynamic values = friendsWrapper[r'$values'];
        if (values is List<dynamic>) {
          friendsData = values;
        } else {
          throw Exception('Giá trị $values không phải danh sách bạn bè hợp lệ');
        }
      } else {
        throw Exception('Không tìm thấy trường trong friends');
      }

    } else if (jsonResponse is List<dynamic>) {
      // Trường hợp API trả về list trực tiếp
      friendsData = jsonResponse;
    } else {
      throw Exception('Phản hồi API không hợp lệ: $jsonResponse');
    }

    return friendsData.map((json) => FriendDTO.fromJson(json)).toList();
  } else {
    throw Exception('Không thể tải danh sách bạn bè: ${response.statusCode}');
  }
}


  Future<List<FriendRequestWithDetails>> getSentFriendRequests(
    int userId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get-sent-requests/$userId'),
    );
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      bool isSuccess;
      if (jsonResponse['success'] is bool) {
        isSuccess = jsonResponse['success'] as bool;
      } else if (jsonResponse['success'] is String) {
        isSuccess = jsonResponse['success'].toLowerCase() == 'true';
      } else {
        throw Exception('Invalid success value: ${jsonResponse['success']}');
      }

      if (isSuccess) {
        final requests = jsonResponse['sentRequests'] as List<dynamic>;
        return requests
            .map((json) => FriendRequestWithDetails.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Failed to load sent friend requests: ${jsonResponse['message']}',
        );
      }
    } else {
      throw Exception(
        'Failed to load sent friend requests: ${response.statusCode}',
      );
    }
  }

  Future<void> cancelFriendRequest(int senderId, int receiverId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cancel-request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'senderId': senderId, 'receiverId': receiverId}),
    );

    if (response.statusCode != 200) {
      final jsonResponse = jsonDecode(response.body);
      throw Exception(
        'Failed to cancel friend request: ${jsonResponse['message']}',
      );
    }
  }

  Future<void> unfriend(int userId, int friendId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/unfriend'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'friendId': friendId}),
    );

    if (response.statusCode != 200) {
      final jsonResponse = jsonDecode(response.body);
      throw Exception('Failed to unfriend: ${jsonResponse['message']}');
    }
  }
}
