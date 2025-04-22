class MemberDTO {
  final int id;
  final String? username; // Sửa thành String? để cho phép null
  final String avatarUrl;
  final String adder;
  final int conversation_id;
  final int user_id;

  MemberDTO({
    required this.id,
    this.username, // Không cần required vì có thể null
    required this.avatarUrl,
    this.adder = 'NO',
    required this.conversation_id,
    required this.user_id
  });

  factory MemberDTO.fromJson(Map<String, dynamic> json) {
    return MemberDTO(
      id: json['id'] as int,
      username: json['username'] as String?, // Parse null được
      avatarUrl: json['avatar_url'] as String,
      adder: json['adder'] as String? ?? 'NO',
      conversation_id: json['conversation_id'] as int,
      user_id: json['user_id'] as int
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'adder': adder,
      'conversation_id' : conversation_id,
      'user_id' : user_id
    };
  }
}
