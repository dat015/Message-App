import 'package:flutter/foundation.dart';

class Participants {
  final int id;
  final int conversationId;
  final int userId;
  final DateTime joinedAt;
  final bool isDeleted;

  Participants({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.joinedAt,
    required this.isDeleted,
  });

  factory Participants.fromJson(Map<String, dynamic> json) {
    return Participants(
      id: json['id'],
      conversationId: json['conversation_id'],
      userId: json['user_id'],
      joinedAt: DateTime.parse(json['joined_at']),
      isDeleted: json['is_deleted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'joined_at': joinedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }
}
