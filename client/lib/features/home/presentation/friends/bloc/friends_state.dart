import 'package:first_app/data/dto/friendrequest_withdetails.dart';
import 'package:first_app/data/models/friendsuggestion.dart';
import 'package:first_app/data/models/user.dart';
import 'package:first_app/data/dto/scanned_user.dart';

abstract class FriendsState {}

class FriendsLoading extends FriendsState {}

class FriendsLoaded extends FriendsState {
  final List<FriendRequestWithDetails> friendRequests;
  final List<FriendRequestWithDetails> sentFriendRequests;
  final List<FriendSuggestion> friendSuggestions;
  final List<User> friends;
  final List<int>? qrCodeData;
  final ScannedUser? scannedUser;

  FriendsLoaded({
    required this.friendRequests,
    required this.sentFriendRequests,
    required this.friendSuggestions,
    required this.friends,
    this.qrCodeData,
    this.scannedUser,
  });

  FriendsLoaded copyWith({
    List<FriendRequestWithDetails>? friendRequests,
    List<FriendRequestWithDetails>? sentFriendRequests,
    List<FriendSuggestion>? friendSuggestions,
    List<User>? friends,
    List<int>? qrCodeData,
    ScannedUser? scannedUser,
  }) {
    return FriendsLoaded(
      friendRequests: friendRequests ?? this.friendRequests,
      sentFriendRequests: sentFriendRequests ?? this.sentFriendRequests,
      friendSuggestions: friendSuggestions ?? this.friendSuggestions,
      friends: friends ?? this.friends,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      scannedUser: scannedUser ?? this.scannedUser,
    );
  }
}

class FriendsSearchSuccess extends FriendsState {
  final List<dynamic> searchResults;

  FriendsSearchSuccess({required this.searchResults});
}

class FriendsError extends FriendsState {
  final String message;
  FriendsError(this.message);
}