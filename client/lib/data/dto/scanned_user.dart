class ScannedUser {
  final int id;
  final String username;
  final String email;
  final String? avatarUrl;
  final String birthday;
  final bool gender;
  final String? interests;
  final String? location;
  final String? bio;
  final int mutualFriendsCount;
  final String relationshipStatus;

  ScannedUser({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    required this.birthday,
    required this.gender,
    this.interests,
    this.location,
    this.bio,
    required this.mutualFriendsCount,
    required this.relationshipStatus,
  });

  factory ScannedUser.fromJson(Map<String, dynamic> json) {
    return ScannedUser(
      id: json['id'] as int? ?? 0, // Use camelCase and provide a default value
      username: json['username'] as String? ?? '', // Use camelCase
      email: json['email'] as String? ?? '', // Use camelCase
      avatarUrl: json['avatarUrl'] as String?, // Use camelCase
      birthday: json['birthday'] as String? ?? '', // Use camelCase
      gender: json['gender'] as bool? ?? false, // Use camelCase
      interests: json['interests'] as String?, // Use camelCase
      location: json['location'] as String?, // Use camelCase
      bio: json['bio'] as String?, // Use camelCase
      mutualFriendsCount: json['mutualFriendsCount'] as int? ?? 0, // Use camelCase
      relationshipStatus: json['relationshipStatus'] as String? ?? '', // Use camelCase
    );
  }
}