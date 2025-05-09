abstract class OtherProfileEvent {}

class LoadProfileEvent extends OtherProfileEvent {
  final bool forceRefresh;
  LoadProfileEvent({this.forceRefresh = false});
}

class SendFriendRequestEvent extends OtherProfileEvent {}

class AcceptFriendRequestEvent extends OtherProfileEvent {}

class CancelFriendRequestEvent extends OtherProfileEvent {}

class RejectFriendRequestEvent extends OtherProfileEvent {}

class UnfriendEvent extends OtherProfileEvent {}