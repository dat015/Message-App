import 'package:first_app/data/dto/friendrequest_withdetails.dart';
import 'package:first_app/data/models/friendsuggestion.dart';
import 'package:first_app/data/models/user.dart';

abstract class FriendsEvent {}

class LoadFriendsDataEvent extends FriendsEvent {}

class AcceptFriendRequestEvent extends FriendsEvent {
  final int requestId;
  final String username;
  final int index;
  AcceptFriendRequestEvent(this.requestId, this.username, this.index);
}

class RejectFriendRequestEvent extends FriendsEvent {
  final int requestId;
  final String username;
  final int index;
  RejectFriendRequestEvent(this.requestId, this.username, this.index);
}

class SendFriendRequestEvent extends FriendsEvent {
  final int receiverId;
  final String username;
  final String avatarUrl;
  final int index;
  SendFriendRequestEvent(this.receiverId, this.username, this.avatarUrl, this.index);
}

class CancelFriendRequestEvent extends FriendsEvent {
  final int requestId;
  final int senderId;
  final int receiverId;
  final String username;
  final int index;
  CancelFriendRequestEvent(this.requestId, this.senderId, this.receiverId, this.username, this.index);
}

class UnfriendEvent extends FriendsEvent {
  final int friendId;
  final String username;
  final int index;
  UnfriendEvent(this.friendId, this.username, this.index);
}

class GenerateUserQrCodeEvent extends FriendsEvent {} // Sự kiện tạo mã QR

class ScanQrCodeEvent extends FriendsEvent {
  final String qrCodeContent;
  ScanQrCodeEvent(this.qrCodeContent); // Sự kiện quét mã QR
}

class SearchUsersEvent extends FriendsEvent {
  final String query;
  SearchUsersEvent(this.query);
}

class ResetSearchEvent extends FriendsEvent {}