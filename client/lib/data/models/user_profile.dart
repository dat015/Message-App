class UserProfile {
  final int id;
  final String username;
  final String email;
  final String? avatarUrl;
  final String birthday;
  final DateTime createdAt;
  final bool gender;
  final String? interests;
  final String? location;
  final String? bio;
  final int? friendsCount;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    required this.birthday,
    required this.createdAt,
    required this.gender,
    this.interests,
    this.location,
    this.bio,
    this.friendsCount,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      birthday: json['birthday'],
      createdAt: DateTime.parse(json['created_at']),
      gender: json['gender'],
      interests: json['interests'],
      location: json['location'],
      bio: json['bio'],
      friendsCount: json['mutualFriendsCount'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
      'birthday': birthday,
      'created_at': createdAt.toIso8601String(), // Chuyển DateTime thành chuỗi ISO 8601
      'gender': gender,
      'interests': interests,
      'location': location,
      'bio': bio,
      'mutualFriendsCount': friendsCount, // Ánh xạ đúng với key trong JSON
    };
  }

  UserProfile copyWith({
    int? id,
    String? username,
    String? avatarUrl,
    String? bio,
    String? interests,
    String? location,
    String? birthday,
    bool? gender,
    int? friendsCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      location: location ?? this.location,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      friendsCount: friendsCount ?? this.friendsCount,
      email: this.email,
      createdAt: this.createdAt,
    );
  }
}