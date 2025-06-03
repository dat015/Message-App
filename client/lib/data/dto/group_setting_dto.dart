class GroupSettingDTO {
  final int? id; // Khóa chính, tự động tăng
  final int conversationId; // Khóa ngoại liên kết với Conversations
  final bool allowMemberInvite;
  final bool allowMemberEdit;
  final int createdBy; // Khóa ngoại liên kết với Users
  final DateTime createdAt; // Thời gian tạo, mặc định là hiện tại
  final bool allowMemberRemove;

  GroupSettingDTO({
    this.id,
    required this.conversationId,
    required this.allowMemberInvite,
    required this.allowMemberEdit,
    required this.createdBy,
    DateTime? createdAt,
    required this.allowMemberRemove,
  }) : createdAt = createdAt ?? DateTime.now();

  factory GroupSettingDTO.fromJson(Map<String, dynamic> json) {
    return GroupSettingDTO(
      id: json['id'],
      conversationId: json['conversationId'],
      allowMemberInvite: json['allowMemberInvite'],
      allowMemberEdit: json['allowMemberEdit'],
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      allowMemberRemove: json['allowMemberRemove'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'allowMemberInvite': allowMemberInvite,
      'allowMemberEdit': allowMemberEdit,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'allowMemberRemove': allowMemberRemove,
    };
  }

  bool checkGroupSetting() {
    if (conversationId <= 0 || createdBy <= 0) {
      throw ArgumentError('ConversationId and CreatedBy must be positive integers');
    }
    return true;
  }
}
