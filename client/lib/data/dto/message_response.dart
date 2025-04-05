import 'package:first_app/data/models/attachment.dart';
import 'package:first_app/data/models/messages.dart';

class MessageDTOForAttachment {
  final int id;
  final String content;
  final int senderId;
  final bool isRead;
  final String? type;
  final bool isFile;
  final DateTime createdAt;
  final int conversationId;

  MessageDTOForAttachment({
    required this.id,
    required this.content,
    required this.senderId,
    this.isRead = false,
    this.type,
    this.isFile = false,
    required this.createdAt,
    required this.conversationId,
  });

  factory MessageDTOForAttachment.fromJson(Map<String, dynamic> json) {
    return MessageDTOForAttachment(
      id: json['id'],
      content: json['content'],
      senderId: json['sender_id'],
      isRead: json['is_read'] ?? false,
      type: json['type'],
      isFile: json['isFile'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      conversationId: json['conversation_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender_id': senderId,
      'is_read': isRead,
      'type': type,
      'isFile': isFile,
      'created_at': createdAt.toIso8601String(),
      'conversation_id': conversationId,
    };
  }
}
class AttachmentDTOForAttachment {
  final int id;
  final String fileUrl;
  final double fileSize;
  final String fileType;
  final DateTime uploadedAt;
  final bool isTemporary;
  final int? messageId;

  AttachmentDTOForAttachment({
    required this.id,
    required this.fileUrl,
    required this.fileSize,
    required this.fileType,
    required this.uploadedAt,
    this.isTemporary = true,
    this.messageId,
  });

  factory AttachmentDTOForAttachment.fromJson(Map<String, dynamic> json) {
    return AttachmentDTOForAttachment(
      id: json['id'],
      fileUrl: json['file_url'],
      fileSize: (json['fileSize'] as num).toDouble(),
      fileType: json['file_type'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
      isTemporary: json['is_temporary'] ?? true,
      messageId: json['message_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_url': fileUrl,
      'fileSize': fileSize,
      'file_type': fileType,
      'uploaded_at': uploadedAt.toIso8601String(),
      'is_temporary': isTemporary,
      'message_id': messageId,
    };
  }
}
class MessageWithAttachment {
  final MessageDTOForAttachment message;
  final AttachmentDTOForAttachment? attachment;

  MessageWithAttachment({
    required this.message,
    this.attachment,
  });

  factory MessageWithAttachment.fromJson(Map<String, dynamic> json) {
    return MessageWithAttachment(
      message: MessageDTOForAttachment.fromJson(json['message']),
      attachment: json['attachment'] != null
          ? AttachmentDTOForAttachment.fromJson(json['attachment'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message.toJson(),
      'attachment': attachment?.toJson(),
    };
  }
}

