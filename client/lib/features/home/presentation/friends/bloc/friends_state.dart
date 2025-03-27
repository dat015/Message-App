import 'package:first_app/data/dto/friendrequest_withdetails.dart';
import 'package:first_app/data/models/friendsuggestion.dart';
import 'package:first_app/data/models/user.dart';

abstract class FriendsState {}

class FriendsLoading extends FriendsState {}

class FriendsLoaded extends FriendsState {
  final List<FriendRequestWithDetails> friendRequests;
  final List<FriendRequestWithDetails> sentFriendRequests;
  final List<FriendSuggestion> friendSuggestions;
  final List<User> friends;

  FriendsLoaded({
    required this.friendRequests,
    required this.sentFriendRequests,
    required this.friendSuggestions,
    required this.friends,
  });
}

class FriendsError extends FriendsState {
  final String message;
  FriendsError(this.message);
}

class FriendsSearchSuccess extends FriendsState {
  final List<dynamic> searchResults;
  FriendsSearchSuccess(this.searchResults);
}