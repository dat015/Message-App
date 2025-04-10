class Post {
  final String? id;
  final String? content;
  final String? imageUrl;
  final String? musicUrl;
  final DateTime createdAt;
  final String? authorId;
  final String? authorName;
  final List<String> taggedFriends;
  final List<String> likes;

  Post({
    this.id,
    this.content,
    this.imageUrl,
    this.musicUrl,
    required this.createdAt,
    this.authorId,
    this.authorName,
    required this.taggedFriends,
    required this.likes,
  });

  // Phương thức toMap để chuyển đổi Post thành Map
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'imageUrl': imageUrl,
      'musicUrl': musicUrl,
      'createdAt': createdAt.toIso8601String(),
      'authorId': authorId,
      'authorName': authorName,
      'taggedFriends': taggedFriends,
      'likes': likes,
    };
  }

  // Phương thức fromMap để chuyển đổi Map thành Post
  factory Post.fromMap(String id, Map<String, dynamic> map) {
    return Post(
      id: id,
      content: map['content'],
      imageUrl: map['imageUrl'],
      musicUrl: map['musicUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      authorId: map['authorId'],
      authorName: map['authorName'],
      taggedFriends: List<String>.from(map['taggedFriends'] ?? []),
      likes: List<String>.from(map['likes'] ?? []),
    );
  }
}