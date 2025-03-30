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
      id: json['Id'] as int,
      username: json['Username'] as String,
      email: json['Email'] as String,
      avatarUrl: json['AvatarUrl'] as String?,
      birthday: json['Birthday'] as String,
      gender: json['Gender'] as bool,
      interests: json['Interests'] as String?,
      location: json['Location'] as String?,
      bio: json['Bio'] as String?,
      mutualFriendsCount: json['MutualFriendsCount'] as int,
      relationshipStatus: json['RelationshipStatus'] as String,
    );
  }
}