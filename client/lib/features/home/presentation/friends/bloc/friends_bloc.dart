import 'package:first_app/data/dto/scanned_user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/dto/friendrequest_withdetails.dart';
import 'package:first_app/data/models/friendsuggestion.dart';
import 'package:first_app/data/models/user.dart';
import 'package:first_app/data/repositories/Friends_repo/friends_repo.dart';
import 'friends_event.dart';
import 'friends_state.dart';
import 'dart:convert'; // Cho base64Decode

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
    on<GenerateUserQrCodeEvent>(_onGenerateUserQrCode); // Thêm xử lý tạo QR
    on<ScanQrCodeEvent>(_onScanQrCode); // Thêm xử lý quét QR
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
        emit(currentState.copyWith(friendRequests: updatedRequests, friends: updatedFriends));
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
        emit(currentState.copyWith(friendRequests: updatedRequests));
      } catch (e) {
        emit(FriendsError('Failed to reject friend request: $e'));
      }
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
    if (state is FriendsLoaded) {
      final currentState = state as FriendsLoaded;
      try {
        await friendsRepo.cancelFriendRequest(event.senderId, event.receiverId);
        final updatedSentRequests = List<FriendRequestWithDetails>.from(currentState.sentFriendRequests)..removeAt(event.index);
        emit(currentState.copyWith(sentFriendRequests: updatedSentRequests));
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
        emit(currentState.copyWith(friends: updatedFriends));
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
      // Convert the API response to a ScannedUser object
      final scannedUser = ScannedUser.fromJson(userData as Map<String, dynamic>);
      emit(currentState.copyWith(scannedUser: scannedUser));
    } catch (e) {
      emit(FriendsError('Không tìm thấy người dùng từ mã QR: $e'));
    }
  }
}
}