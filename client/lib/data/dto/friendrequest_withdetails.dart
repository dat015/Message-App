// lib/data/models/friend_request_with_details.dart

import 'package:first_app/data/models/friends.dart';
import 'package:first_app/data/models/friendrequest.dart';

class FriendRequestWithDetails {
  final FriendRequest request;
  final Friend friend;

  FriendRequestWithDetails({required this.request, required this.friend});

  factory FriendRequestWithDetails.fromJson(Map<String, dynamic> json) {
    return FriendRequestWithDetails(
      request: FriendRequest.fromJson(json),
      friend: Friend.fromJson(json),
    );
  }
}
