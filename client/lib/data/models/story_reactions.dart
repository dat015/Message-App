import 'package:flutter/foundation.dart';

class Story {
  final int id;
  final int userId;
  final String content; // Image or video URL
  final DateTime createdAt;
  final DateTime expiresAt;

  Story({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.expiresAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}

class StoryReaction {
  final int id;
  final int userId;
  final int storyId;
  final String reactionType; // like, love, haha, wow, sad, angry
  final DateTime createdAt;
  final bool isDeleted;

  StoryReaction({
    required this.id,
    required this.userId,
    required this.storyId,
    required this.reactionType,
    required this.createdAt,
    required this.isDeleted,
  });

  factory StoryReaction.fromJson(Map<String, dynamic> json) {
    return StoryReaction(
      id: json['id'],
      userId: json['user_id'],
      storyId: json['story_id'],
      reactionType: json['reaction_type'],
      createdAt: DateTime.parse(json['created_at']),
      isDeleted: json['is_deleted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'story_id': storyId,
      'reaction_type': reactionType,
      'created_at': createdAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }
}
