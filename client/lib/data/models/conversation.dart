import 'group_settings.dart';
import 'messages.dart';
import 'participants.dart';

class Conversation {
  int? id;
  String name;
  final bool isGroup;
  final DateTime createdAt;
  DateTime? lastMessageTime;
  String? lastMessage;
  String? lastMessageSender;
  String? img_url;
  List<Message>? messages;
  List<GroupSettings>? groupSettings;
  List<Participants>? participants;

  Conversation({
    this.id,
    required this.name,
    this.isGroup = false,
    required this.createdAt,
    this.lastMessageTime,
    this.lastMessage,
    this.lastMessageSender,
    this.messages,
    this.groupSettings,
    this.participants,
    this.img_url,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      isGroup: json['is_group'] == true || json['is_group'] == 'true',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'] as String)
          : null,
      lastMessage: json['lastMessage'] as String?,
      lastMessageSender: json['lastMessageSender'] as String?,
      messages: json['messages'] != null && json['messages'] is List
          ? (json['messages'] as List<dynamic>)
              .map((item) => Message.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      img_url: json['img_url'] as String?,
      groupSettings: json['groupSettings'] != null && json['groupSettings'] is List
          ? (json['groupSettings'] as List<dynamic>)
              .map((item) => GroupSettings.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      participants: json['participants'] != null && json['participants'] is Map
          ? (json['participants'][r'$values'] as List<dynamic>?)
              ?.map((item) => Participants.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_group': isGroup,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageSender': lastMessageSender,
      'messages': messages?.map((message) => message.toJson()).toList(),
      'groupSettings': groupSettings?.map((settings) => settings.toJson()).toList(),
      'participants': participants?.map((participant) => participant.toJson()).toList(),
      'img_url': img_url,
    };
  }

  bool validate() {
    if (name.isEmpty || name.length > 100) {
      print('Validation failed: Name must be between 1 and 100 characters');
      return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'Conversation(id: $id, name: $name, isGroup: $isGroup, createdAt: $createdAt, '
        'lastMessageTime: $lastMessageTime, lastMessage: $lastMessage, lastMessageSender: $lastMessageSender, '
        'messages: ${messages?.length ?? 0}, groupSettings: ${groupSettings?.length ?? 0}, participants: ${participants?.length ?? 0}, img_url: $img_url)';
  }
}
