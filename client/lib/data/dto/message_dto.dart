// message_dto.dart
class MessageDTO {
  String content;
  int senderId;
  int conversationId;
  int? attachmentId;

  MessageDTO({
    required this.content,
    required this.senderId,
    required this.conversationId,
    this.attachmentId,
  });

  factory MessageDTO.fromJson(Map<String, dynamic> json) {
    return MessageDTO(
      content: json['content'] as String,
      senderId: json['sender_id'] as int,
      conversationId: json['conversation_id'] as int,
      attachmentId: json['attachment_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'sender_id': senderId,
      'conversation_id': conversationId,
      'attachment_id': attachmentId,
    };
  }
}