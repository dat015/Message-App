import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String? imageUrl;
  final String? videoUrl;
  final String? musicUrl;
  final int? musicStartTime;
  final int? musicDuration;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewers;
  final Map<String, String> reactions;
  final String visibility; // Thêm trường visibility

  Story({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    this.imageUrl,
    this.videoUrl,
    this.musicUrl,
    this.musicStartTime,
    this.musicDuration,
    required this.createdAt,
    required this.expiresAt,
    this.viewers = const [],
    this.reactions = const {},
    this.visibility = 'public', // Mặc định là công khai
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
        musicUrl: map['musicUrl'],
        musicStartTime: map['musicStartTime'],
        musicDuration: map['musicDuration'],
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        expiresAt: (map['expiresAt'] as Timestamp).toDate(),
        viewers: List<String>.from(map['viewers'] ?? []),
        reactions: Map<String, String>.from(map['reactions'] ?? {}),
        visibility: map['visibility'] ?? 'public',
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
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'musicUrl': musicUrl,
      'musicStartTime': musicStartTime,
      'musicDuration': musicDuration,
      'viewers': viewers,
      'reactions': reactions,
      'visibility': visibility, // Thêm vào map
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isImage => imageUrl != null;
  bool get isVideo => videoUrl != null;
  bool get hasMusic => musicUrl != null;
}