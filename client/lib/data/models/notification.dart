import 'package:flutter/foundation.dart';

class NotificationModel {
  final int id;
  final String relatedType; // request friend, accept friend, story reaction, ...
  final String content;
  final DateTime createdAt;
  final int userId;
  final bool isSeen;
  final int relatedId;

  NotificationModel({
    required this.id,
    required this.relatedType,
    required this.content,
    required this.createdAt,
    required this.userId,
    required this.isSeen,
    required this.relatedId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      relatedType: json['related_type'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      userId: json['user_id'],
      isSeen: json['is_seen'],
      relatedId: json['related_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'related_type': relatedType,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'is_seen': isSeen,
      'related_id': relatedId,
    };
  }
}
