import 'dart:convert';
import 'package:first_app/PlatformClient/config.dart';
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
      // Check if 'requests' is a map and contains '$values'
      final requestsData = jsonResponse['requests'];
      if (requestsData is Map<String, dynamic> && requestsData.containsKey('\$values')) {
        final requests = requestsData['\$values'] as List<dynamic>;
        return requests
            .map((json) => FriendRequestWithDetails.fromJson(json))
            .toList();
      } else if (requestsData is List<dynamic>) {
        // If 'requests' is already a list, use it directly
        return requestsData
            .map((json) => FriendRequestWithDetails.fromJson(json))
            .toList();
      } else {
        throw Exception('Invalid response format: requests is neither a list nor a map with \$values');
      }
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
      final suggestionsData = jsonResponse['suggestions'];
      if (suggestionsData is Map<String, dynamic> && suggestionsData.containsKey('\$values')) {
        final suggestions = suggestionsData['\$values'] as List<dynamic>;
        return suggestions
            .map((json) => FriendSuggestion.fromJson(json))
            .toList();
      } else if (suggestionsData is List<dynamic>) {
        return suggestionsData
            .map((json) => FriendSuggestion.fromJson(json))
            .toList();
      } else {
        throw Exception('Invalid response format: suggestions is neither a list nor a map with \$values');
      }
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

  Future<void> sendFriendRequest(int senderId, int receiverId, String username, String avatarUrl) async {
    final response = await http.post(
      Uri.parse('$baseUrl/send-request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'senderId': senderId, 'receiverId': receiverId, 'username' : username, 'status' : 'Pending', 'avatarUrl' : avatarUrl}),
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
      final friendsData = jsonResponse['friends'];
      if (friendsData is Map<String, dynamic> && friendsData.containsKey('\$values')) {
        final friends = friendsData['\$values'] as List<dynamic>;
        return friends.map((json) => User.fromJson(json)).toList();
      } else if (friendsData is List<dynamic>) {
        return friendsData.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Invalid response format: friends is neither a list nor a map with \$values');
      }
    } else {
      throw Exception('Failed to load friends: ${jsonResponse['message']}');
    }
  } else {
    throw Exception('Failed to load friends: ${response.statusCode}');
  }
}

  Future<List<FriendRequestWithDetails>> getSentFriendRequests(int userId) async {
  final response = await http.get(Uri.parse('$baseUrl/get-sent-requests/$userId'));
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
      final requestsData = jsonResponse['sentRequests'];
      if (requestsData is Map<String, dynamic> && requestsData.containsKey('\$values')) {
        final requests = requestsData['\$values'] as List<dynamic>;
        return requests.map((json) => FriendRequestWithDetails.fromJson(json)).toList();
      } else if (requestsData is List<dynamic>) {
        return requestsData.map((json) => FriendRequestWithDetails.fromJson(json)).toList();
      } else {
        throw Exception('Invalid response format: sentRequests is neither a list nor a map with \$values');
      }
    } else {
      throw Exception('Failed to load sent friend requests: ${jsonResponse['message']}');
    }
  } else {
    throw Exception('Failed to load sent friend requests: ${response.statusCode}');
  }
}

  Future<void> cancelFriendRequest(int senderId, int receiverId) async {
  final response = await http.post(
    Uri.parse('$baseUrl/cancel-request'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'senderId': senderId, 'receiverId' : receiverId}),
  );

  if (response.statusCode != 200) {
    final jsonResponse = jsonDecode(response.body);
    throw Exception('Failed to cancel friend request: ${jsonResponse['message']}');
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
