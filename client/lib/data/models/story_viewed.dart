import 'package:flutter/foundation.dart';

class StoryViewer {
  final int id;
  final int storyId;
  final int userId;
  final DateTime viewedAt;

  StoryViewer({
    required this.id,
    required this.storyId,
    required this.userId,
    required this.viewedAt,
  });

  factory StoryViewer.fromJson(Map<String, dynamic> json) {
    return StoryViewer(
      id: json['id'],
      storyId: json['story_id'],
      userId: json['user_id'],
      viewedAt: DateTime.parse(json['viewed_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'story_id': storyId,
      'user_id': userId,
      'viewed_at': viewedAt.toIso8601String(),
    };
  }
}
