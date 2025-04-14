import 'package:first_app/data/models/conversation.dart';
import 'package:first_app/data/models/user.dart';
import 'package:flutter/foundation.dart';

class Participants {
  final int id;
  final int conversationId;
  final int userId;
  final String? role; // Có thể null, giống C#
  String? name; // Có thể null, giống C#
  final DateTime joinedAt;
  final bool isDeleted;
  final Conversation? conversation; // Mối quan hệ ForeignKey, có thể null
  final User? user; // Mối quan hệ ForeignKey, có thể null

  Participants({
    required this.id,
    required this.conversationId,
    required this.userId,
    this.role, // Tùy chọn, không yêu cầu
    this.name, // Tùy chọn, không yêu cầu
    required this.joinedAt,
    required this.isDeleted,
    this.conversation, // Tùy chọn
    this.user, // Tùy chọn
  });

  factory Participants.fromJson(Map<String, dynamic> json) {
    print('Parsing participant: $json');
    final userIdRaw = json['user_id'];
    return Participants(
      id: json['id'] as int? ?? 0,
      conversationId: json['conversation_id'] as int? ?? 0,
      userId:
          userIdRaw is int
              ? userIdRaw
              : int.tryParse(userIdRaw?.toString() ?? '') ?? 0,
      role: json['role'] as String?,
      name: json['name'] as String?,
      joinedAt:
          json['joined_at'] != null
              ? DateTime.parse(json['joined_at'] as String)
              : DateTime.now(),
      isDeleted: json['is_deleted'] as bool? ?? false,
      conversation:
          json['conversation'] != null &&
                  json['conversation'] is Map &&
                  json['conversation'].containsKey(r'$ref')
              ? null
              : json['conversation'] != null
              ? Conversation.fromJson(
                json['conversation'] as Map<String, dynamic>,
              )
              : null,
      user:
          json['user'] != null
              ? User.fromJson(json['user'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'role': role,
      'name': name,
      'joined_at': joinedAt.toIso8601String(),
      'is_deleted': isDeleted,
      'conversation': conversation?.toJson(),
      'user': user?.toJson(),
    };
  }
}
