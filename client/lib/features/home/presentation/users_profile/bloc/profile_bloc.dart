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
    on<UnfriendEvent>(_onUnfriend);
  }

  Future<void> _onLoadProfile(LoadProfileEvent event, Emitter<OtherProfileState> emit) async {
    emit(OtherProfileLoading());
    try {
      if (!event.forceRefresh && _cachedProfile != null) {
        final friendStatus = await _checkFriendStatus(_cachedProfile!);
        emit(OtherProfileLoaded(_cachedProfile!, friendStatus));
        return;
      }

      final profile = await profileRepository.fetchOtherUserProfile(viewerId, targetUserId);
      _cachedProfile = profile;
      final friendStatus = await _checkFriendStatus(profile);
      emit(OtherProfileLoaded(profile, friendStatus));
    } catch (e) {
      emit(OtherProfileError('Lỗi khi tải hồ sơ: $e'));
    }
  }

  Future<void> _onSendFriendRequest(SendFriendRequestEvent event, Emitter<OtherProfileState> emit) async {
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

  Future<void> _onAcceptFriendRequest(AcceptFriendRequestEvent event, Emitter<OtherProfileState> emit) async {
    if (state is OtherProfileLoaded) {
      try {
        final request = (await friendsRepo.getFriendRequests(viewerId))
            .firstWhere((req) => req.friend.senderId == targetUserId);
        await friendsRepo.acceptFriendRequest(request.request.id);
        await _refreshProfile(emit);
      } catch (e) {
        emit(OtherProfileError('Lỗi khi chấp nhận: $e'));
      }
    }
  }

  Future<void> _onCancelFriendRequest(CancelFriendRequestEvent event, Emitter<OtherProfileState> emit) async {
    if (state is OtherProfileLoaded) {
      try {
        await friendsRepo.cancelFriendRequest(viewerId, targetUserId);
        await _refreshProfile(emit);
      } catch (e) {
        emit(OtherProfileError('Lỗi khi hủy lời mời: $e'));
      }
    }
  }

  Future<void> _onUnfriend(UnfriendEvent event, Emitter<OtherProfileState> emit) async {
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
      final profile = await profileRepository.fetchOtherUserProfile(viewerId, targetUserId);
      _cachedProfile = profile;
      final friendStatus = await _checkFriendStatus(profile);
      emit(OtherProfileLoaded(profile, friendStatus));
    } catch (e) {
      emit(OtherProfileError('Lỗi khi làm mới hồ sơ: $e'));
    }
  }

  Future<String> _checkFriendStatus(UserProfile profile) async {
    try {
      final friends = await friendsRepo.getFriends(viewerId);
      if (friends.any((friend) => friend.id == targetUserId)) {
        return "friend";
      }

      final friendRequests = await friendsRepo.getFriendRequests(viewerId);
      if (friendRequests.any((req) => req.friend.senderId == targetUserId)) {
        return "pending";
      }

      final sentRequests = await friendsRepo.getSentFriendRequests(viewerId);
      if (sentRequests.any((req) => req.friend.receiverId == targetUserId)) {
        return "sent";
      }

      return "none";
    } catch (e) {
      return "none";
    }
  }
}