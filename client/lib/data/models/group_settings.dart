import 'package:first_app/data/models/user.dart';

import 'conversation.dart';

class GroupSettings {
  int? id; // Nullable vì là auto-increment trong database
  int conversationId; // Khóa ngoại tới Conversation
  bool privacy;
  bool allowMemberInvite;
  bool allowMemberEdit;
  int createdBy; // Khóa ngoại tới User
  DateTime createdAt;
  bool isActive;
  String? imageUrl; // Nullable vì không có [Required] trong C#
  Conversation? conversation; // Mối quan hệ với Conversation
  User? user; // Mối quan hệ với User

  // Constructor với các thuộc tính bắt buộc và giá trị mặc định
  GroupSettings({
    this.id,
    required this.conversationId,
    this.privacy = false,
    this.allowMemberInvite = true,
    this.allowMemberEdit = true,
    required this.createdBy,
    DateTime? createdAt,
    this.isActive = true,
    this.imageUrl,
    this.conversation,
    this.user,
  }) : createdAt = createdAt ?? DateTime.now();

  // Factory constructor để tạo từ JSON
  factory GroupSettings.fromJson(Map<String, dynamic> json) {
    return GroupSettings(
      id: json['Id'] as int?,
      conversationId: json['ConversationId'] as int,
      privacy: json['Privacy'] as bool,
      allowMemberInvite: json['AllowMemberInvite'] as bool,
      allowMemberEdit: json['AllowMemberEdit'] as bool,
      createdBy: json['CreatedBy'] as int,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      isActive: json['IsActive'] as bool,
      imageUrl: json['ImageUrl'] as String?,
      conversation: json['Conversation'] != null
          ? Conversation.fromJson(json['Conversation'] as Map<String, dynamic>)
          : null,
      user: json['User'] != null
          ? User.fromJson(json['User'] as Map<String, dynamic>)
          : null,
    );
  }

  // Chuyển đối tượng thành JSON
  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'ConversationId': conversationId,
      'Privacy': privacy,
      'AllowMemberInvite': allowMemberInvite,
      'AllowMemberEdit': allowMemberEdit,
      'CreatedBy': createdBy,
      'CreatedAt': createdAt.toIso8601String(),
      'IsActive': isActive,
      'ImageUrl': imageUrl,
      'Conversation': conversation?.toJson(),
      'User': user?.toJson(),
    };
  }

  // Validation cơ bản dựa trên các ràng buộc trong C#
  bool validate() {
    // Kiểm tra imageUrl: tối đa 255 ký tự (nếu có)
    if (imageUrl != null && imageUrl!.length > 255) {
      print('Validation failed: ImageUrl must not exceed 255 characters');
      return false;
    }

    return true;
  }

  @override
  String toString() {
    return 'GroupSettings(id: $id, conversationId: $conversationId, privacy: $privacy, '
        'allowMemberInvite: $allowMemberInvite, allowMemberEdit: $allowMemberEdit, '
        'createdBy: $createdBy, createdAt: $createdAt, isActive: $isActive, imageUrl: $imageUrl)';
  }
}


