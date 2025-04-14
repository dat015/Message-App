import 'group_settings.dart';
import 'messages.dart';
import 'participants.dart';

class Conversation {
  int? id; // Nullable vì là auto-increment trong database
   String name;
  final bool isGroup;
  final DateTime createdAt;
  DateTime? lastMessageTime;
  String? lastMessage;
  String? lastMessageSender;
  List<Message>? messages; // Tương ứng với ICollection<Message>
  List<GroupSettings>? groupSettings; // Tương ứng với ICollection<GroupSettings>
  List<Participants>? participants; // Tương ứng với ICollection<Participants>

  // Constructor với các thuộc tính bắt buộc và giá trị mặc định
  Conversation({
    this.id,
    required this.name,
    this.isGroup = false, // Giá trị mặc định là false
    required this.createdAt,
    this.lastMessageTime,
    this.lastMessage,
    this.lastMessageSender,
    this.messages,
    this.groupSettings,
    this.participants,
  });

  // Factory constructor để tạo từ JSON
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '', // Thêm giá trị mặc định nếu null
      isGroup: json['is_group'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(), // Giá trị mặc định nếu null
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
      groupSettings:
          json['groupSettings'] != null && json['groupSettings'] is List
              ? (json['groupSettings'] as List<dynamic>)
                  .map((item) => GroupSettings.fromJson(item as Map<String, dynamic>))
                  .toList()
              : null,
      participants:
          json['participants'] != null && json['participants'] is Map
              ? (json['participants'][r'$values'] as List<dynamic>?)
                  ?.map((item) => Participants.fromJson(item as Map<String, dynamic>))
                  .toList()
              : null,
    );
  }

  // Chuyển đối tượng thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_group': isGroup,
      'created_at': createdAt.toIso8601String(),
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageSender': lastMessageSender,
      'Messages': messages?.map((message) => message.toJson()).toList(),
      'GroupSettings': groupSettings?.map((settings) => settings.toJson()).toList(),
      'Participants': participants?.map((participant) => participant.toJson()).toList(),
    };
  }

  // Validation cơ bản dựa trên các ràng buộc trong C#
  bool validate() {
    // Kiểm tra name: tối đa 100 ký tự
    if (name.isEmpty || name.length > 100) {
      print('Validation failed: Name must be between 1 and 100 characters');
      return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'Conversation(id: $id, name: $name, isGroup: $isGroup, createdAt: $createdAt, lastMessageTime: $lastMessageTime, lastMessage: $lastMessage, lastMessageSender: $lastMessageSender, messages: ${messages?.length ?? 0}, groupSettings: ${groupSettings?.length ?? 0}, participants: ${participants?.length ?? 0})';
  }
}