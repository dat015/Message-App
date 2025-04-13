import 'dart:convert';
import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/dto/friendrequest_withdetails.dart';
import 'package:first_app/data/dto/scanned_user.dart';
import 'package:first_app/data/models/friendsuggestion.dart';
import 'package:first_app/data/models/user.dart';
import 'package:first_app/data/repositories/Friends_repo/friends_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    on<GenerateUserQrCodeEvent>(_onGenerateUserQrCode);
    on<ScanQrCodeEvent>(_onScanQrCode);
    on<SearchUsersEvent>(_onSearchUsers);
    on<ResetSearchEvent>(_onResetSearch);
    add(LoadFriendsDataEvent());
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
    try {
      await friendsRepo.acceptFriendRequest(event.requestId);
      await _updateAfterFriendAction(event.index, emit, newStatus: 'Accepted');
    } catch (e) {
      emit(FriendsError('Failed to accept friend request: $e'));
    }
  }

  Future<void> _onRejectFriendRequest(RejectFriendRequestEvent event, Emitter<FriendsState> emit) async {
    try {
      await friendsRepo.rejectFriendRequest(event.requestId);
      await _updateAfterFriendAction(event.index, emit, newStatus: 'Rejected');
    } catch (e) {
      emit(FriendsError('Failed to reject friend request: $e'));
    }
  }

  Future<void> _onSendFriendRequest(SendFriendRequestEvent event, Emitter<FriendsState> emit) async {
    if (state is FriendsLoaded) {
      final currentState = state as FriendsLoaded;
      try {
        await friendsRepo.sendFriendRequest(currentUserId, event.receiverId, event.username, event.avatarUrl);
        final updatedSuggestions = List<FriendSuggestion>.from(currentState.friendSuggestions)..removeAt(event.index);
        final updatedSentRequests = await friendsRepo.getSentFriendRequests(currentUserId);
        emit(currentState.copyWith(friendSuggestions: updatedSuggestions, sentFriendRequests: updatedSentRequests));
      } catch (e) {
        emit(FriendsError('Failed to send friend request: $e'));
      }
    }
  }

  Future<void> _onCancelFriendRequest(CancelFriendRequestEvent event, Emitter<FriendsState> emit) async {
    try {
      await friendsRepo.cancelFriendRequest(event.senderId, event.receiverId);
      await _updateAfterFriendAction(event.index, emit, newStatus: 'NotSent');
    } catch (e) {
      emit(FriendsError('Failed to cancel friend request: $e'));
    }
  }

  Future<void> _updateAfterFriendAction(int index, Emitter<FriendsState> emit, {String? newStatus}) async {
    if (state is FriendsLoaded) {
      final currentState = state as FriendsLoaded;
      if (newStatus == 'Accepted') {
        final updatedRequests = List<FriendRequestWithDetails>.from(currentState.friendRequests);
        if (index < updatedRequests.length) {
          updatedRequests.removeAt(index);
        }
        final updatedFriends = await friendsRepo.getFriends(currentUserId);
        emit(currentState.copyWith(friendRequests: updatedRequests, friends: updatedFriends));
      } else if (newStatus == 'Rejected') {
        final updatedRequests = List<FriendRequestWithDetails>.from(currentState.friendRequests);
        if (index < updatedRequests.length) {
          updatedRequests.removeAt(index);
        }
        emit(currentState.copyWith(friendRequests: updatedRequests));
      } else if (newStatus == 'PendingSent') {
        final updatedSuggestions = List<FriendSuggestion>.from(currentState.friendSuggestions);
        if (index < updatedSuggestions.length) {
          updatedSuggestions.removeAt(index);
        }
        final updatedSentRequests = await friendsRepo.getSentFriendRequests(currentUserId);
        emit(currentState.copyWith(friendSuggestions: updatedSuggestions, sentFriendRequests: updatedSentRequests));
      } else if (newStatus == 'NotSent') {
        final updatedSentRequests = List<FriendRequestWithDetails>.from(currentState.sentFriendRequests);
        if (index < updatedSentRequests.length) {
          updatedSentRequests.removeAt(index);
        }
        emit(currentState.copyWith(sentFriendRequests: updatedSentRequests));
      }
    } else if (state is FriendsSearchSuccess) {
      final currentState = state as FriendsSearchSuccess;
      final updatedResults = List<dynamic>.from(currentState.searchResults);
      if (index < updatedResults.length) {
        updatedResults[index]['relationshipStatus'] = newStatus;
        if (newStatus == 'Accepted' || newStatus == 'Rejected') {
          updatedResults[index].remove('requestId');
        }
      }
      emit(FriendsSearchSuccess(searchResults: updatedResults));
    }
  }

  Future<void> _onUnfriend(UnfriendEvent event, Emitter<FriendsState> emit) async {
    if (state is FriendsLoaded) {
      final currentState = state as FriendsLoaded;
      try {
        await friendsRepo.unfriend(currentUserId, event.friendId);
        final updatedFriends = List<User>.from(currentState.friends)..removeAt(event.index);
        emit(currentState.copyWith(friends: updatedFriends));
      } catch (e) {
        emit(FriendsError('Failed to unfriend: $e'));
      }
    }
  }

  Future<void> _onGenerateUserQrCode(GenerateUserQrCodeEvent event, Emitter<FriendsState> emit) async {
    if (state is FriendsLoaded) {
      final currentState = state as FriendsLoaded;
      try {
        final response = await apiClient.get('api/user/generate-qr/$currentUserId');
        final String base64String = response['qrCode'];
        final List<int> qrCodeBytes = base64Decode(base64String.split(',').last);
        emit(currentState.copyWith(qrCodeData: qrCodeBytes));
      } catch (e) {
        emit(FriendsError('Failed to generate QR code: $e'));
      }
    }
  }

  Future<void> _onScanQrCode(ScanQrCodeEvent event, Emitter<FriendsState> emit) async {
    if (state is FriendsLoaded) {
      final currentState = state as FriendsLoaded;
      try {
        final userData = await apiClient.post(
          'api/user/find-user-by-qr',
          data: {'qrCodeContent': event.qrCodeContent, 'currentUserId': currentUserId},
        );
        final scannedUser = ScannedUser.fromJson(userData as Map<String, dynamic>);
        emit(currentState.copyWith(scannedUser: scannedUser));
      } catch (e) {
        emit(FriendsError('Không tìm thấy người dùng từ mã QR: $e'));
      }
    }
  }

  Future<void> _onSearchUsers(SearchUsersEvent event, Emitter<FriendsState> emit) async {
    if (event.query.isEmpty) {
      emit(FriendsSearchSuccess(searchResults: []));
      return;
    }
    try {
      final response = await apiClient.get('api/friends/search?username=${event.query}&senderId=$currentUserId');
      final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
      final List<dynamic> searchResults = responseMap['\$values'] ?? [];
      final processedResults = searchResults.map((user) {
        final result = Map<String, dynamic>.from(user as Map<String, dynamic>);
        result['relationshipStatus'] = user['relationshipStatus'] ?? 'NotSent';
        if (result['relationshipStatus'] == 'PendingReceived' && user['requestId'] != null) {
          result['requestId'] = user['requestId'];
        }
        return result;
      }).toList();
      emit(FriendsSearchSuccess(searchResults: processedResults));
    } catch (e) {
      emit(FriendsError('Failed to search users: $e'));
    }
  }

  Future<void> _onResetSearch(ResetSearchEvent event, Emitter<FriendsState> emit) async {
    print('ResetSearchEvent triggered'); // Debug log
    if (state is FriendsLoaded) {
      print('Current state is FriendsLoaded, reusing existing data'); // Debug log
      final currentState = state as FriendsLoaded;
      emit(currentState); // Reuse existing data if available
      return;
    }
    print('Reloading friends data'); // Debug log
    emit(FriendsLoading());
    try {
      final friendRequests = await friendsRepo.getFriendRequests(currentUserId);
      final sentFriendRequests = await friendsRepo.getSentFriendRequests(currentUserId);
      final friendSuggestions = await friendsRepo.getFriendSuggestions(currentUserId);
      final friends = await friendsRepo.getFriends(currentUserId);
      print('Loaded data: ${friendRequests.length} requests, ${sentFriendRequests.length} sent, '
          '${friendSuggestions.length} suggestions, ${friends.length} friends'); // Debug log
      emit(FriendsLoaded(
        friendRequests: friendRequests,
        sentFriendRequests: sentFriendRequests,
        friendSuggestions: friendSuggestions,
        friends: friends,
      ));
    } catch (e) {
      print('Error resetting search: $e'); // Debug log
      emit(FriendsError('Failed to reset search: $e'));
    }
  }
}