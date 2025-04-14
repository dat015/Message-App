class Post {
  final String? id;
  final String? content;
  final String? imageUrl;
  final String? musicUrl;
  final DateTime createdAt;
  final String authorAvatar;
  final String? authorId;
  final String? authorName;
  final List<String> taggedFriends;
  final List<String> likes;
  final String visibility;

  Post({
    this.id,
    this.content,
    this.imageUrl,
    this.musicUrl,
    required this.createdAt,
    required this.authorAvatar,
    this.authorId,
    this.authorName,
    required this.taggedFriends,
    required this.likes,
    this.visibility = 'public', // Mặc định là công khai
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'imageUrl': imageUrl,
      'musicUrl': musicUrl,
      'createdAt': createdAt.toIso8601String(),
      'authorAvatar': authorAvatar,
      'authorId': authorId,
      'authorName': authorName,
      'taggedFriends': taggedFriends,
      'likes': likes,
      'visibility': visibility, // Thêm vào map
    };
  }

  factory Post.fromMap(String id, Map<String, dynamic> map) {
    return Post(
      id: id,
      content: map['content'],
      imageUrl: map['imageUrl'],
      musicUrl: map['musicUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      authorAvatar: map['authorAvatar'] ?? '',
      authorId: map['authorId'],
      authorName: map['authorName'],
      taggedFriends: List<String>.from(map['taggedFriends'] ?? []),
      likes: List<String>.from(map['likes'] ?? []),
      visibility: map['visibility'] ?? 'public',
    );
  }
}