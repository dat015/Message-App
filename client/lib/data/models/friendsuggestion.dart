// friend_suggestion.dart
class FriendSuggestion {
  final int userId;
  final String username;
  final String avatarUrl;
  final int mutualFriendsCount;
  final int commonInterestsCount;
  final bool sameLocation;
  final String? bio;

  FriendSuggestion({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.mutualFriendsCount,
    required this.commonInterestsCount,
    required this.sameLocation,
    this.bio,
  });

  factory FriendSuggestion.fromJson(Map<String, dynamic> json) {
    return FriendSuggestion(
      userId: json['userId'] as int? ?? 0,
      username: json['username'] as String? ?? 'Unknown',
      avatarUrl: json['avatarUrl'] as String? ?? 'https://via.placeholder.com/150',
      mutualFriendsCount: json['mutualFriendsCount'] as int? ?? 0,
      commonInterestsCount: json['commonInterestsCount'] as int? ?? 0,
      sameLocation: json['sameLocation'] as bool? ?? false,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'avatarUrl': avatarUrl,
      'mutualFriendsCount': mutualFriendsCount,
      'commonInterestsCount': commonInterestsCount,
      'sameLocation': sameLocation,
      'bio': bio,
    };
  }
}