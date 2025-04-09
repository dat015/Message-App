import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewers;
  final Map<String, String> reactions;

  Story({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    this.imageUrl,
    this.videoUrl,
    required this.createdAt,
    required this.expiresAt,
    this.viewers = const [],
    this.reactions = const {},
  });

  factory Story.fromMap(String id, Map<String, dynamic> map) {
    try {
      return Story(
        id: id,
        authorId: map['authorId'] ?? '',
        authorName: map['authorName'] ?? '',
        authorAvatar: map['authorAvatar'] ?? '',
        imageUrl: map['imageUrl'],
        videoUrl: map['videoUrl'],
        createdAt: (map['createdAt'] as Timestamp).toDate(), // Parse từ Timestamp
        expiresAt: (map['expiresAt'] as Timestamp).toDate(), // Parse từ Timestamp
        viewers: List<String>.from(map['viewers'] ?? []),
        reactions: Map<String, String>.from(map['reactions'] ?? {}),
      );
    } catch (e) {
      print('Error parsing story: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'createdAt': Timestamp.fromDate(createdAt), // Lưu dưới dạng Timestamp
      'expiresAt': Timestamp.fromDate(expiresAt), // Lưu dưới dạng Timestamp
      'viewers': viewers,
      'reactions': reactions,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isImage => imageUrl != null;
  bool get isVideo => videoUrl != null;
}