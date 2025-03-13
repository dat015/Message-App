class Message {
  int? id; // Nullable vì là auto-increment trong database
  String content;
  int senderId;
  bool isRead;
  DateTime createdAt;
  int conversationId; // Khóa ngoại tới Conversation

  // Constructor với các thuộc tính bắt buộc và giá trị mặc định
  Message({
    this.id,
    required this.content,
    required this.senderId,
    this.isRead = false,
    DateTime? createdAt,
    required this.conversationId,
  }) : createdAt = createdAt ?? DateTime.now();

  // Factory constructor để tạo từ JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int?, // Có thể null
      content: json['content'] as String, // Bắt buộc, giả định không null
      senderId: json['sender_id'] as int, // Bắt buộc
      isRead: json['is_read'] as bool, // Bắt buộc, có giá trị mặc định là false
      createdAt: DateTime.parse(json['created_at'] as String), // Chuyển từ String sang DateTime
      conversationId: json['conversation_id'] as int, // Bắt buộc
    );
  }

  // Chuyển đối tượng thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender_id': senderId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'conversation_id': conversationId,
    };
  }

  // Validation cơ bản dựa trên các ràng buộc
  bool validate() {
    // Kiểm tra content: độ dài từ 1 đến 500 ký tự
    if (content.isEmpty || content.length > 500) {
      print('Validation failed: Content must be between 1 and 500 characters');
      return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'Message(id: $id, content: $content, senderId: $senderId, isRead: $isRead, '
        'createdAt: $createdAt, conversationId: $conversationId)';
  }
}