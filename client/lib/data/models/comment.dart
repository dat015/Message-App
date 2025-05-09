import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> likes;
  final String? parentCommentId;
  final String? mediaUrl;
  final String? mediaType;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    required this.likes,  
    this.parentCommentId,
    this.mediaUrl,
    this.mediaType,
  });

  factory Comment.fromMap(String id, Map<String, dynamic> map) {
    return Comment(
      id: id,
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['updatedAt'] as String))
          : null,
      likes: List<String>.from(map['likes'] ?? []),
      parentCommentId: map['parentCommentId'],
      mediaUrl: map['mediaUrl'],
      mediaType: map['mediaType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt,
      'likes': likes,
      'parentCommentId': parentCommentId,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
    };
  }
}