class MessageStatus {
  int? id; // Nullable vì là auto-increment trong database
  int messageId; // Khóa ngoại tới Message
  int receiverId; // Khóa ngoại tới User
  String status;
  DateTime updatedAt;

  // Constructor với các thuộc tính bắt buộc và giá trị mặc định
  MessageStatus({
    this.id,
    required this.messageId,
    required this.receiverId,
    required this.status,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  // Factory constructor để tạo từ JSON
  factory MessageStatus.fromJson(Map<String, dynamic> json) {
    return MessageStatus(
      id: json['id'] as int?,
      messageId: json['message_id'] as int,
      receiverId: json['receiver_id'] as int,
      status: json['status'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Chuyển đối tượng thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'receiver_id': receiverId,
      'status': status,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Validation cơ bản dựa trên các ràng buộc
  bool validate() {
    // Kiểm tra status: tối đa 50 ký tự
    if (status.isEmpty || status.length > 50) {
      print('Validation failed: Status must be between 1 and 50 characters');
      return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'MessageStatus(id: $id, messageId: $messageId, receiverId: $receiverId, '
        'status: $status, updatedAt: $updatedAt)';
  }
}