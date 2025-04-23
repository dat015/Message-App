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
  bool _hasLoadedFriendsData = false;
  bool _isSearching = false;

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
    if (!_hasLoadedFriendsData) {
      add(LoadFriendsDataEvent());
    }
  }

  Future<void> _onLoadFriendsData(LoadFriendsDataEvent event, Emitter<FriendsState> emit) async {
    if (_isSearching) {
      print('Skipping LoadFriendsDataEvent because search is active');
      return;
    }
    emit(FriendsLoading());
    try {
      final friendRequests = await friendsRepo.getFriendRequests(currentUserId);
      final sentFriendRequests = await friendsRepo.getSentFriendRequests(currentUserId);
      final friendSuggestions = await friendsRepo.getFriendSuggestions(currentUserId);
      final friends = await friendsRepo.getFriends(currentUserId);
      _hasLoadedFriendsData = true;
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
      await _updateAfterFriendAction(event.index, emit, newStatus: 'Friend');
    } catch (e) {
      emit(FriendsError('Failed to accept friend request: $e'));
    }
  }

  Future<void> _onRejectFriendRequest(RejectFriendRequestEvent event, Emitter<FriendsState> emit) async {
    try {
      await friendsRepo.rejectFriendRequest(event.requestId);
      await _updateAfterFriendAction(event.index, emit, newStatus: 'None');
    } catch (e) {
      emit(FriendsError('Failed to reject friend request: $e'));
    }
  }

  Future<void> _onSendFriendRequest(SendFriendRequestEvent event, Emitter<FriendsState> emit) async {
    if (state is FriendsLoaded || state is FriendsSearchSuccess) {
      try {
        await friendsRepo.sendFriendRequest(
          currentUserId,
          event.receiverId,
          event.username,
          event.avatarUrl,
        );
        if (state is FriendsLoaded) {
          final currentState = state as FriendsLoaded;
          final updatedSuggestions = List<FriendSuggestion>.from(currentState.friendSuggestions)
            ..removeWhere((s) => s.userId == event.receiverId);
          final updatedSentRequests = await friendsRepo.getSentFriendRequests(currentUserId);
          emit(currentState.copyWith(
            friendSuggestions: updatedSuggestions,
            sentFriendRequests: updatedSentRequests,
          ));
        } else if (state is FriendsSearchSuccess) {
          final currentState = state as FriendsSearchSuccess;
          final updatedResults = List<dynamic>.from(currentState.searchResults);
          if (event.index < updatedResults.length) {
            updatedResults[event.index]['relationshipStatus'] = 'SentRequest';
            // Lấy requestId từ API nếu cần (giả sử API trả về requestId)
            updatedResults[event.index]['requestId'] = 0; // Cần API trả về requestId
          }
          emit(FriendsSearchSuccess(searchResults: updatedResults));
        }
      } catch (e) {
        emit(FriendsError('Failed to send friend request: $e'));
      }
    }
  }

  Future<void> _onCancelFriendRequest(CancelFriendRequestEvent event, Emitter<FriendsState> emit) async {
    try {
      await friendsRepo.cancelFriendRequest(event.senderId, event.receiverId);
      await _updateAfterFriendAction(event.index, emit, newStatus: 'None');
    } catch (e) {
      emit(FriendsError('Failed to cancel friend request: $e'));
    }
  }

  Future<void> _updateAfterFriendAction(int index, Emitter<FriendsState> emit, {String? newStatus}) async {
    if (state is FriendsLoaded) {
      final currentState = state as FriendsLoaded;
      if (newStatus == 'Friend') {
        final updatedRequests = List<FriendRequestWithDetails>.from(currentState.friendRequests);
        if (index < updatedRequests.length) {
          updatedRequests.removeAt(index);
        }
        final updatedFriends = await friendsRepo.getFriends(currentUserId);
        emit(currentState.copyWith(friendRequests: updatedRequests, friends: updatedFriends));
      } else if (newStatus == 'None') {
        final updatedRequests = List<FriendRequestWithDetails>.from(currentState.friendRequests);
        final updatedSentRequests = List<FriendRequestWithDetails>.from(currentState.sentFriendRequests);
        if (index < updatedRequests.length) {
          updatedRequests.removeAt(index);
        } else if (index < updatedSentRequests.length) {
          updatedSentRequests.removeAt(index);
        }
        emit(currentState.copyWith(
          friendRequests: updatedRequests,
          sentFriendRequests: updatedSentRequests,
        ));
      }
    } else if (state is FriendsSearchSuccess) {
      final currentState = state as FriendsSearchSuccess;
      final updatedResults = List<dynamic>.from(currentState.searchResults);
      if (index < updatedResults.length) {
        updatedResults[index]['relationshipStatus'] = newStatus;
        if (newStatus == 'Friend' || newStatus == 'None') {
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
  _isSearching = true;
  emit(FriendsLoading());
  try {
    final response = await apiClient.get('api/Friends/search?email=${Uri.encodeQueryComponent(event.query)}&senderId=$currentUserId');
    
    // Kiểm tra kiểu của response
    List<dynamic> searchResults;
    if (response is List) {
      searchResults = response;
    } else if (response is Map<String, dynamic>) {
      // ASP.NET Core thường trả về dạng {"$values": [...]}
      searchResults = response['\$values'] ?? response['values'] ?? [];
      if (searchResults is! List) {
        throw Exception('Response does not contain a valid list of users');
      }
    } else {
      throw Exception('Unexpected response format: $response');
    }

    final processedResults = searchResults.map((user) {
      final result = Map<String, dynamic>.from(user as Map<String, dynamic>);
      result['relationshipStatus'] = user['relationshipStatus'] ?? 'None';
      if (result['relationshipStatus'] == 'ReceivedRequest' || result['relationshipStatus'] == 'SentRequest') {
        result['requestId'] = user['requestId'] ?? 0;
      }
      return result;
    }).toList();
    emit(FriendsSearchSuccess(searchResults: processedResults));
  } catch (e) {
    emit(FriendsError('Không tìm thấy người dùng: $e'));
  }
}

  Future<void> _onResetSearch(ResetSearchEvent event, Emitter<FriendsState> emit) async {
    print('ResetSearchEvent triggered');
    _isSearching = false;
    if (state is FriendsSearchSuccess) {
      emit(FriendsSearchSuccess(searchResults: []));
    }
  }
}