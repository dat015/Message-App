// lib/data/models/friend_request.dart

class FriendRequest {
  final int id; // requestId
  final int senderId;
  final int receiverId;
  final String status;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
  });

  // Factory method để ánh xạ từ JSON
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as int,
      senderId: json['senderId'] as int,
      receiverId: json['receiverId'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Phương thức để chuyển đổi thành JSON (nếu cần gửi dữ liệu lên backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}