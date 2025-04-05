class Message {
  int? id;
  String content;
  String type;
  int senderId;
  bool isRead;
  DateTime createdAt;
  int conversationId;
  bool isFile; // Thêm thuộc tính isFile

  Message({
    this.id,
    required this.content,
    required this.senderId,
    this.type = 'text',
    this.isRead = false,
    DateTime? createdAt,
    required this.conversationId,
    this.isFile = false, // Giá trị mặc định là false
  }) : createdAt = createdAt ?? DateTime.now();

  // Factory constructor từ JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int?, // Có thể null
      content: json['content'] ?? "", // Nếu null, dùng chuỗi rỗng
      senderId: json['sender_id'] as int? ?? 0, // Nếu null, mặc định 0
      isRead: json['is_read'] as bool? ?? false, // Nếu null, mặc định false
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
              : DateTime.now(), // Nếu null hoặc parse lỗi, dùng DateTime.now()
      conversationId:
          json['conversation_id'] as int? ?? 0, // Nếu null, mặc định 0
      type: json['type'] as String? ?? 'text', // Nếu null, mặc định 'text'
      isFile: json['is_file'] as bool? ?? false, // Nếu null, mặc định false
    );
  }

  // Chuyển đổi đối tượng thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type,
      'sender_id': senderId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'conversation_id': conversationId,
      'is_file': isFile, // Thêm isFile vào JSON
    };
  }

  // Kiểm tra hợp lệ
  bool validate() {
    if (content.isEmpty || content.length > 500) {
      print('Validation failed: Content must be between 1 and 500 characters');
      return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'Message(id: $id, content: $content, type: $type, senderId: $senderId, isRead: $isRead, '
        'createdAt: $createdAt, conversationId: $conversationId, isFile: $isFile)';
  }
}
