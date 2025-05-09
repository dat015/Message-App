class ConversationDto {
  final int id;
  final String? name; // Cập nhật là String? để chấp nhận null
  final bool isGroup;
  final DateTime createdAt;
  final String? lastMessage; // Cập nhật là String? để chấp nhận null
  final int? lastMessageSender;
  final DateTime? lastMessageTime;
  final String? imgUrl; // Cập nhật là String? để chấp nhận null
  final List<ParticipantDto> participants;

  ConversationDto({
    required this.id,
    this.name,
    required this.isGroup,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageSender,
    this.lastMessageTime,
    this.imgUrl,
    required this.participants,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) {
    var participantsJson = json['participants'];
    List<ParticipantDto> participantsList = [];

    if (participantsJson != null && participantsJson.containsKey(r'$values')) {
      var values = participantsJson[r'$values'] as List;
      participantsList = values.map((e) => ParticipantDto.fromJson(e)).toList();
    }

    return ConversationDto(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      isGroup: json['is_group'] as bool? ?? false,
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
              : DateTime.now(),
      lastMessage: json['lastMessage'] as String?,
      lastMessageSender: json['lastMessageSender'] as int?,
      lastMessageTime:
          json['lastMessageTime'] != null
              ? DateTime.tryParse(json['lastMessageTime'])
              : null,
      imgUrl: json['img_url'] as String?,
      participants: participantsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_group': isGroup,
      'createdAt': createdAt.toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageSender': lastMessageSender,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'img_url': imgUrl,
      'participants': participants.map((e) => e.toJson()).toList(),
    };
  }
}

class ParticipantDto {
  final int id;
  final int userId;
  final int conversationId;
  final String? name;  // Cho phép null
  final bool isDeleted;
  final String? imgUrl;

  ParticipantDto({
    required this.id,
    required this.userId,
    required this.conversationId,
    this.name,  // Không required
    required this.isDeleted,
    this.imgUrl,
  });

  factory ParticipantDto.fromJson(Map<String, dynamic> json) {
    return ParticipantDto(
      id: json['id'] as int? ?? 0,  // Xử lý null
      userId: json['user_id'] as int? ?? 0,  // Lưu ý: 'user_id' thay vì 'userId'
      conversationId: json['conversationId'] as int? ?? 0,
      name: json['name'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      imgUrl: json['img_url'] as String?,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'conversationId': conversationId,
      'name': name,
      'isDeleted': isDeleted,
      'img_url': imgUrl,
    };
  }
}
