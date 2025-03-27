class UserProfile {
  final int id;
  final String username;
  final String email;
  final String avatarUrl;
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
    required this.avatarUrl,
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
      avatarUrl: json['avatar_url'] ?? 'https://randomuser.me/api/portraits/men/1.jpg',
      birthday: json['birthday'],
      createdAt: DateTime.parse(json['created_at']),
      gender: json['gender'],
      interests: json['interests'],
      location: json['location'],
      bio: json['bio'],
      friendsCount: json['mutualFriendsCount'] as int?,
    );
  }
}