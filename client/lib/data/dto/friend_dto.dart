class FriendDTO {
  final String? username;
  final String? avatar;
  final int? friendId;
  final int? userId;

  FriendDTO({
    this.username,
    this.avatar,
    this.friendId,
    this.userId,
  });

  factory FriendDTO.fromJson(Map<String, dynamic> json) {
    return FriendDTO(
      username: json['username'] as String?,
      avatar: json['avatar'] as String?,
      friendId: json['friendId'] as int?,
      userId: json['userId'] as int?,
    );
  }
}