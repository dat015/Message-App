abstract class SearchUsersEvent {}

class SendFriendRequestEvent extends SearchUsersEvent {
  final int receiverId;
  final String username;
  final int index;
  SendFriendRequestEvent(this.receiverId, this.username, this.index);
}

class CancelFriendRequestEvent extends SearchUsersEvent {
  final int receiverId;
  final String username;
  final int index;
  CancelFriendRequestEvent(this.receiverId, this.username, this.index);
}

class UpdateWebSocketMessageEvent extends SearchUsersEvent {
  final Map<String, dynamic> message;
  UpdateWebSocketMessageEvent(this.message);
}

class UpdateConnectionStateEvent extends SearchUsersEvent {
  final bool isConnected;
  UpdateConnectionStateEvent(this.isConnected);
}