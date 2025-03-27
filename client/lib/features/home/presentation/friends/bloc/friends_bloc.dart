import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/dto/friendrequest_withdetails.dart';
import 'package:first_app/data/models/friendsuggestion.dart';
import 'package:first_app/data/models/user.dart';
import 'package:first_app/data/repositories/Friends_repo/friends_repo.dart';
import 'friends_event.dart';
import 'friends_state.dart';

class FriendsBloc extends Bloc<FriendsEvent, FriendsState> {
  final FriendsRepo friendsRepo;
  final ApiClient apiClient;
  final int currentUserId;

  FriendsBloc({
    required this.friendsRepo,
    required this.apiClient,
    required this.currentUserId,
  }) : super(FriendsLoading()) {
    on<LoadFriendsDataEvent>(_onLoadFriendsData);
    on<AcceptFriendRequestEvent>(_onAcceptFriendRequest);
    on<RejectFriendRequestEvent>(_onRejectFriendRequest);
    on<SendFriendRequestEvent>(_onSendFriendRequest);
    on<CancelFriendRequestEvent>(_onCancelFriendRequest);
    on<UnfriendEvent>(_onUnfriend);
    on<SearchUsersEvent>(_onSearchUsers);
  }

  Future<void> _onLoadFriendsData(LoadFriendsDataEvent event, Emitter<FriendsState> emit) async {
    emit(FriendsLoading());
    try {
      final friendRequests = await friendsRepo.getFriendRequests(currentUserId);
      final sentFriendRequests = await friendsRepo.getSentFriendRequests(currentUserId);
      final friendSuggestions = await friendsRepo.getFriendSuggestions(currentUserId);
      final friends = await friendsRepo.getFriends(currentUserId);

      emit(FriendsLoaded(
        friendRequests: friendRequests,
        sentFriendRequests: sentFriendRequests,
        friendSuggestions: friendSuggestions,
        friends: friends,
      ));
    } catch (e) {
      emit(FriendsError('Failed to load friends data: $e'));
    }
  }

  Future<void> _onAcceptFriendRequest(AcceptFriendRequestEvent event, Emitter<FriendsState> emit) async {
    if (state is FriendsLoaded) {
      final currentState = state as FriendsLoaded;
      try {
        await friendsRepo.acceptFriendRequest(event.requestId);
        final updatedRequests = List<FriendRequestWithDetails>.from(currentState.friendRequests)..removeAt(event.index);
        final updatedFriends = await friendsRepo.getFriends(currentUserId);
        emit(FriendsLoaded(
          friendRequests: updatedRequests,
          sentFriendRequests: currentState.sentFriendRequests,
          friendSuggestions: currentState.friendSuggestions,
          friends: updatedFriends,
        ));
      } catch (e) {
        emit(FriendsError('Failed to accept friend request: $e'));
      }
    }
  }

  Future<void> _onRejectFriendRequest(RejectFriendRequestEvent event, Emitter<FriendsState> emit) async {
    if (state is FriendsLoaded) {
      final currentState = state as FriendsLoaded;
      try {
        await friendsRepo.rejectFriendRequest(event.requestId);
        final updatedRequests = List<FriendRequestWithDetails>.from(currentState.friendRequests)..removeAt(event.index);
        emit(FriendsLoaded(
          friendRequests: updatedRequests,
          sentFriendRequests: currentState.sentFriendRequests,
          friendSuggestions: currentState.friendSuggestions,
          friends: currentState.friends,
        ));
      } catch (e) {
        emit(FriendsError('Failed to reject friend request: $e'));
      }
    }
  }

  Future<void> _onSendFriendRequest(SendFriendRequestEvent event, Emitter<FriendsState> emit) async {
    if (state is FriendsLoaded) {
      final currentState = state as FriendsLoaded;
      try {
        await friendsRepo.sendFriendRequest(
          currentUserId,
          event.receiverId,
          event.username,
          event.avatarUrl,
        );
        final updatedSuggestions = List<FriendSuggestion>.from(currentState.friendSuggestions)..removeAt(event.index);
        final updatedSentRequests = await friendsRepo.getSentFriendRequests(currentUserId);
        emit(FriendsLoaded(
          friendRequests: currentState.friendRequests,
          sentFriendRequests: updatedSentRequests,
          friendSuggestions: updatedSuggestions,
          friends: currentState.friends,
        ));
      } catch (e) {
        emit(FriendsError('Failed to send friend request: $e'));
      }
    }
  }

  Future<void> _onCancelFriendRequest(CancelFriendRequestEvent event, Emitter<FriendsState> emit) async {
    if (state is FriendsLoaded) {
      final currentState = state as FriendsLoaded;
      try {
        await friendsRepo.cancelFriendRequest(event.senderId, event.receiverId);
        final updatedSentRequests = List<FriendRequestWithDetails>.from(currentState.sentFriendRequests)..removeAt(event.index);
        emit(FriendsLoaded(
          friendRequests: currentState.friendRequests,
          sentFriendRequests: updatedSentRequests,
          friendSuggestions: currentState.friendSuggestions,
          friends: currentState.friends,
        ));
      } catch (e) {
        emit(FriendsError('Failed to cancel friend request: $e'));
      }
    }
  }

  Future<void> _onUnfriend(UnfriendEvent event, Emitter<FriendsState> emit) async {
    if (state is FriendsLoaded) {
      final currentState = state as FriendsLoaded;
      try {
        await friendsRepo.unfriend(currentUserId, event.friendId);
        final updatedFriends = List<User>.from(currentState.friends)..removeAt(event.index);
        emit(FriendsLoaded(
          friendRequests: currentState.friendRequests,
          sentFriendRequests: currentState.sentFriendRequests,
          friendSuggestions: currentState.friendSuggestions,
          friends: updatedFriends,
        ));
      } catch (e) {
        emit(FriendsError('Failed to unfriend: $e'));
      }
    }
  }

  Future<void> _onSearchUsers(SearchUsersEvent event, Emitter<FriendsState> emit) async {
    if (event.query.isEmpty) return;
    try {
      final response = await apiClient.get('api/friends/search?username=${event.query}&senderId=$currentUserId');
      emit(FriendsSearchSuccess(response as List<dynamic>));
    } catch (e) {
      emit(FriendsError('Failed to search users: $e'));
    }
  }
}