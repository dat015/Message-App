class Friend {
  int id;
  int senderId;
  int receiverId;
  String status;
  DateTime createdAt;
  String username;
  String avatarUrl;
  int mutualFriendsCount;

  Friend({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    required this.username,
    required this.avatarUrl,
    required this.mutualFriendsCount,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    try {
      return Friend(
        id: _parseInt(json['id']),
        senderId: _parseInt(json['senderId']),
        receiverId: _parseInt(json['receiverId']),
        status: json['status'] as String? ?? 'Unknown',
        createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
        username: json['username'] as String? ?? 'Unknown',
        avatarUrl: json['avatarUrl'] as String? ?? 'https://via.placeholder.com/150',
        mutualFriendsCount: _parseInt(json['mutualFriendsCount']),
      );
    } catch (e) {
      print('Error parsing Friend JSON: $json');
      print('Error: $e');
      rethrow;
    }
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.parse(value);
    throw Exception('Cannot parse $value to int');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'username': username,
      'avatarUrl': avatarUrl,
    };
  }

  @override
  String toString() {
    return 'Friend(id: $id, senderId: $senderId, receiverId: $receiverId, status: $status, createdAt: $createdAt, username: $username)';
  }
}