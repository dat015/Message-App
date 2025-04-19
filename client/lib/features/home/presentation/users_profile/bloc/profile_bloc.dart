import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:first_app/data/models/user_profile.dart';
import 'package:first_app/data/repositories/Chat/User_Profile_repo/us_profile_repository.dart';
import 'package:first_app/data/repositories/Friends_repo/friends_repo.dart';
import 'package:first_app/features/home/presentation/users_profile/bloc/profile_event.dart';
import 'package:first_app/features/home/presentation/users_profile/bloc/profile_state.dart';

class OtherProfileBloc extends Bloc<OtherProfileEvent, OtherProfileState> {
  final UsProfileRepository profileRepository;
  final FriendsRepo friendsRepo;
  final int viewerId;
  final int targetUserId;
  UserProfile? _cachedProfile;

  OtherProfileBloc({
    required this.profileRepository,
    required this.friendsRepo,
    required this.viewerId,
    required this.targetUserId,
  }) : super(OtherProfileLoading()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<SendFriendRequestEvent>(_onSendFriendRequest);
    on<AcceptFriendRequestEvent>(_onAcceptFriendRequest);
    on<CancelFriendRequestEvent>(_onCancelFriendRequest);
    on<RejectFriendRequestEvent>(_onRejectFriendRequest);
    on<UnfriendEvent>(_onUnfriend);
  }

  Future<void> _onLoadProfile(
  LoadProfileEvent event,
  Emitter<OtherProfileState> emit,
) async {
  try {
    emit(OtherProfileLoading());

    // Fetch user profile
    final user = await profileRepository.fetchOtherUserProfile(viewerId, targetUserId);

    // Get friend status and friends using _checkFriendStatus
    final result = await _checkFriendStatus();

    emit(
      OtherProfileLoaded(
        profile: user,
        friendStatus: result['friendStatus'],
        friends: result['friends'],
      ),
    );
  } catch (e) {
    emit(OtherProfileError('Lỗi khi tải hồ sơ: $e'));
  }
}

  Future<void> _onSendFriendRequest(
    SendFriendRequestEvent event,
    Emitter<OtherProfileState> emit,
  ) async {
    if (state is OtherProfileLoaded) {
      final currentState = state as OtherProfileLoaded;
      try {
        await friendsRepo.sendFriendRequest(
          viewerId,
          targetUserId,
          currentState.profile.username,
          currentState.profile.avatarUrl,
        );
        await _refreshProfile(emit);
      } catch (e) {
        emit(OtherProfileError('Lỗi khi gửi lời mời: $e'));
      }
    }
  }

  Future<void> _onAcceptFriendRequest(
    AcceptFriendRequestEvent event,
    Emitter<OtherProfileState> emit,
  ) async {
    if (state is OtherProfileLoaded) {
      try {
        final request = (await friendsRepo.getFriendRequests(
          viewerId,
        )).firstWhere((req) => req.friend.senderId == targetUserId);
        await friendsRepo.acceptFriendRequest(request.request.id);
        await _refreshProfile(emit);
      } catch (e) {
        emit(OtherProfileError('Lỗi khi chấp nhận: $e'));
      }
    }
  }

  Future<void> _onRejectFriendRequest(
    RejectFriendRequestEvent event,
    Emitter<OtherProfileState> emit,
  ) async {
    if (state is OtherProfileLoaded) {
      try {
        final request = (await friendsRepo.getFriendRequests(
          viewerId,
        )).firstWhere((req) => req.friend.senderId == targetUserId);
        await friendsRepo.rejectFriendRequest(request.request.id);
        await _refreshProfile(emit);
      } catch (e) {
        emit(OtherProfileError('Lỗi khi từ chối: $e'));
      }
    }
  }

  Future<void> _onCancelFriendRequest(
    CancelFriendRequestEvent event,
    Emitter<OtherProfileState> emit,
  ) async {
    if (state is OtherProfileLoaded) {
      try {
        await friendsRepo.cancelFriendRequest(viewerId, targetUserId);
        await _refreshProfile(emit);
      } catch (e) {
        emit(OtherProfileError('Lỗi khi hủy lời mời: $e'));
      }
    }
  }

  Future<void> _onUnfriend(
    UnfriendEvent event,
    Emitter<OtherProfileState> emit,
  ) async {
    if (state is OtherProfileLoaded) {
      try {
        await friendsRepo.unfriend(viewerId, targetUserId);
        await _refreshProfile(emit);
      } catch (e) {
        emit(OtherProfileError('Lỗi khi hủy kết bạn: $e'));
      }
    }
  }

  Future<void> _refreshProfile(Emitter<OtherProfileState> emit) async {
  emit(OtherProfileLoading());
  try {
    final user = await profileRepository.fetchUserProfile(targetUserId);
    final profile = await profileRepository.fetchOtherUserProfile(
      viewerId,
      targetUserId,
    );
    _cachedProfile = profile;
    final result = await _checkFriendStatus();
    emit(
      OtherProfileLoaded(
        profile: user,
        friendStatus: result['friendStatus'],
        friends: result['friends'],
      ),
    );
  } catch (e) {
    emit(OtherProfileError('Lỗi khi làm mới hồ sơ: $e'));
  }
}

  Future<Map<String, dynamic>> _checkFriendStatus() async {
  try {
    final friends = await friendsRepo.getFriends(targetUserId); // Fetch target user's friends
    if (friends.any((friend) => friend.id == viewerId)) {
      return {'friendStatus': 'friend', 'friends': friends};
    }

    final friendRequests = await friendsRepo.getFriendRequests(viewerId);
    if (friendRequests.any((req) => req.friend.senderId == targetUserId)) {
      return {'friendStatus': 'pending', 'friends': friends};
    }

    final sentRequests = await friendsRepo.getSentFriendRequests(viewerId);
    if (sentRequests.any((req) => req.friend.receiverId == targetUserId)) {
      return {'friendStatus': 'sent', 'friends': friends};
    }

    return {'friendStatus': 'none', 'friends': friends};
  } catch (e) {
    return {'friendStatus': 'none', 'friends': []};
  }
}
}
