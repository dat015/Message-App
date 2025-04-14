import 'package:first_app/PlatformClient/config.dart';
import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/dto/login_response.dart';
import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/models/conversation.dart';
import 'package:first_app/data/models/participants.dart';
import 'package:first_app/data/repositories/Conversations_repo/conversations_repository.dart';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';
import 'package:first_app/data/repositories/Participants_Repo/participants_repo.dart';
import 'package:first_app/data/repositories/User_Repo/user_repo.dart';
import 'package:flutter/material.dart';
import '../../../routes/routes.dart';
import 'layout/main_layout.dart';

class HomeScreen extends StatefulWidget {
  final LoginResponse user;
  const HomeScreen({super.key, required this.user});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ApiClient _apiService = ApiClient();
  final UserRepo userRepo = UserRepo();
  List<Conversation> _conversations = [];
  List<Participants> _participants = [];
  late int userId;
  ConversationRepo conversationRepo = ConversationRepo();
  ParticipantsRepo participantsRepo = ParticipantsRepo();
  WebSocketService? _webSocketService;
  Map<int, String> userNames = {}; // Lưu trữ userId -> username

  @override
  void initState() {
    userId = widget.user.user!.id;
    print('User ID: $userId');
    super.initState();
    _fetchConversations(); // Gọi hàm để lấy danh sách ban đầu
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    _webSocketService = WebSocketService(
      url: Config.baseUrlWS,
      onMessageReceived: (MessageWithAttachment message) {
        updateChatList(message);
      },
    );

    // Kết nối WebSocket sau khi đã có danh sách conversation
    _fetchConversations().then((_) {
      for (var conversation in _conversations) {
        if (conversation.id != null) {
          _webSocketService?.connect(userId, conversation.id!);
        }
      }
    });
  }

  Future<String> _getUserName(int userId) async {
    try {
      final response = await userRepo.getUser(userId);
      return response.username ?? 'Unknown';
    } catch (e) {
      print("Error fetching username for userId $userId: $e");
      return 'Unknown';
    }
  }

  Future<void> _fetchConversations() async {
    try {
      final conversations = await conversationRepo.getConversations(userId);
      print("Thanh cong");
      for (var conversation in conversations) {
        if (!conversation.isGroup && conversation.participants != null) {
          final otherParticipant = conversation.participants!.firstWhere(
            (p) => p.userId != userId,
            orElse:
                () => Participants(
                  id: 0,
                  conversationId: conversation.id ?? 0,
                  userId: 0,
                  joinedAt: DateTime.now(),
                  isDeleted: false,
                  name: conversation.name,
                ),
          );
          conversation.name = otherParticipant.name ?? conversation.name;
          print("Conversation ${conversation.id}: ${conversation.name}");
          print("Selected participant name: ${otherParticipant.name}");
        }
      }
      setState(() {
        _conversations = conversations;
      });
    } catch (e) {
      print("Error in _fetchConversations: $e");
    }
  }

  String getNewName(String content) {
    if (content.startsWith("Đã đổi tên nhóm thành ")) {
      return content.replaceFirst("Đã đổi tên nhóm thành ", "");
    } else if (content.startsWith("Đã đổi tên bạn thành ")) {
      return content.replaceFirst("Đã đổi tên bạn thành ", "");
    }
    return content;
  }

  // Sử dụng trong code:
  void updateChatList(MessageWithAttachment newMessage) {
    setState(() {
      if (newMessage.message.type == "system" &&
          (newMessage.message.content.startsWith("Đã đổi tên nhóm thành") ||
              newMessage.message.content.startsWith("Đã đổi tên bạn thành"))) {
        final index = _conversations.indexWhere(
          (chat) => chat.id == newMessage.message.conversationId,
        );

        if (index != -1) {
          // Sử dụng hàm getNewName để lấy tên mới
          final newName = getNewName(newMessage.message.content);

          

          // Cập nhật thông tin tin nhắn cuối cùng
          _conversations[index].lastMessage = newMessage.message.content;
          _conversations[index].lastMessageTime = newMessage.message.createdAt;
          _conversations[index].lastMessageSender = "Hệ thống";

          // Di chuyển conversation lên đầu danh sách
          final updatedConversation = _conversations.removeAt(index);
          _conversations.insert(0, updatedConversation);
        }
      } else {
        final index = _conversations.indexWhere(
          (chat) => chat.id == newMessage.message.conversationId,
        );

        if (index != -1) {
          // Cập nhật tin nhắn cuối cùng cho conversation hiện có
          _conversations[index].lastMessage = newMessage.message.content;
          _conversations[index].lastMessageTime = newMessage.message.createdAt;

          // Di chuyển conversation lên đầu danh sách
          final updatedConversation = _conversations.removeAt(index);
          _conversations.insert(0, updatedConversation);
        } else {
          // Tạo conversation mới nếu chưa tồn tại
          Conversation newConversation = Conversation(
            id: newMessage.message.conversationId,
            name: 'New Conversation',
            createdAt: DateTime.now(),
            isGroup: false,
            lastMessage: newMessage.message.content,
            lastMessageTime: newMessage.message.createdAt,
          );
          _conversations.insert(0, newConversation);
        }
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: TextFormField(
          decoration: InputDecoration(
            hintText: 'Hỏi GroqCloud AI hoặc tìm kiếm',
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
            prefixIcon: const Icon(Icons.circle, color: Colors.blueAccent),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
          ),
          onFieldSubmitted: (value) {},
        ),
      ),
    );
  }

  Widget _buildChatList() {
    if (_conversations.isEmpty) {
      return const Center(child: Text('No conversations found'));
    }

    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final chat = _conversations[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(
                  'https://via.placeholder.com/150',
                ),
                backgroundColor: Colors.grey[200],
              ),
              if (!chat.isGroup)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            chat.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Text(
            chat.lastMessage ?? 'No messages yet',
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                chat.lastMessageTime != null
                    ? chat.lastMessageTime!.toString().substring(11, 16)
                    : chat.createdAt.toString().substring(11, 16),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          onTap: () async {
            final int? finalConversationId =
                chat.id != null
                    ? (chat.id is int ? chat.id : int.parse(chat.id.toString()))
                    : 0;
            final int finalUserId = userId;
            int? participantId;

            if (!chat.isGroup && finalConversationId != 0) {
              print("Current User ID: $finalUserId");
              print("Conversation ID: $finalConversationId");

              // Kiểm tra participants
              if (chat.participants != null && chat.participants!.isNotEmpty) {
                // Lọc participants hợp lệ
                final validParticipants =
                    chat.participants!
                        .where((p) => p.userId != 0 && !p.isDeleted)
                        .toList();

                print(
                  "Valid Participants: ${validParticipants.map((p) => 'ID: ${p.id}, UserID: ${p.userId}, Name: ${p.name}').join(', ')}",
                );

                // Tìm participant khác
                final otherParticipant = validParticipants.firstWhere(
                  (p) => p.userId != finalUserId,
                  orElse:
                      () => Participants(
                        id: 0,
                        conversationId: finalConversationId ?? 0,
                        userId: 0,
                        joinedAt: DateTime.now(),
                        isDeleted: false,
                        name: '',
                      ),
                );

                print(
                  "Other Participant: ID=${otherParticipant.id}, UserID=${otherParticipant.userId}, Name=${otherParticipant.name}",
                );

                // Gán participantId
                if (otherParticipant.userId != 0) {
                  participantId = otherParticipant.userId;
                  print("Selected Participant ID: $participantId");
                } else {
                  print("No valid participant found, fetching from API...");
                  try {
                    final updatedParticipants = await ParticipantsRepo()
                        .getParticipants(finalConversationId ?? 0);
                    print(
                      "Fetched Participants: ${updatedParticipants.map((p) => 'ID: ${p.id}, UserID: ${p.userId}, Name: ${p.name}').join(', ')}",
                    );
                    final updatedOtherParticipant = updatedParticipants
                        .firstWhere(
                          (p) =>
                              p.userId != finalUserId &&
                              p.userId != 0 &&
                              !p.isDeleted,
                          orElse:
                              () => Participants(
                                id: 0,
                                conversationId: finalConversationId ?? 0,
                                userId: 0,
                                joinedAt: DateTime.now(),
                                isDeleted: false,
                                name: '',
                              ),
                        );
                    if (updatedOtherParticipant.userId != 0) {
                      participantId = updatedOtherParticipant.userId;
                      chat.participants =
                          updatedParticipants; // Cập nhật participants
                      print("Updated Participant ID: $participantId");
                    } else {
                      print("No valid participant after fetch");
                    }
                  } catch (e) {
                    print("Error fetching participants: $e");
                  }
                }
              } else {
                print("No participants found, fetching from API...");
                try {
                  final updatedParticipants = await ParticipantsRepo()
                      .getParticipants(finalConversationId ?? 0);
                  print(
                    "Fetched Participants: ${updatedParticipants.map((p) => 'ID: ${p.id}, UserID: ${p.userId}, Name: ${p.name}').join(', ')}",
                  );
                  final updatedOtherParticipant = updatedParticipants
                      .firstWhere(
                        (p) =>
                            p.userId != finalUserId &&
                            p.userId != 0 &&
                            !p.isDeleted,
                        orElse:
                            () => Participants(
                              id: 0,
                              conversationId: finalConversationId ?? 0,
                              userId: 0,
                              joinedAt: DateTime.now(),
                              isDeleted: false,
                              name: '',
                            ),
                      );
                  if (updatedOtherParticipant.userId != 0) {
                    participantId = updatedOtherParticipant.userId;
                    chat.participants = updatedParticipants;
                    print("Updated Participant ID: $participantId");
                  } else {
                    print("No valid participant after fetch");
                  }
                } catch (e) {
                  print("Error fetching participants: $e");
                }
              }
            } else {
              print("Group chat or invalid conversation ID");
            }

            print(
              "Navigating to ChatScreen with Participant ID: $participantId",
            );
            final result = await Navigator.pushNamed(
              context,
              AppRoutes.chat,
              arguments: {
                'conversationId': finalConversationId,
                'user_id': finalUserId,
                'participantId': participantId,
              },
            );

            // Xử lý kết quả từ ChatScreen
            if (result is Conversation) {
              _fetchConversations();
              setState(() {
                final index = _conversations.indexWhere(
                  (c) => c.id == result.id,
                );
                if (index != -1) {
                  _conversations[index] = result;
                }
              });
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _webSocketService?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentUserId: userId,
      currentUserName: widget.user.user!.username,
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
      body: Column(
        children: [_buildSearchBar(), Expanded(child: _buildChatList())],
      ),
    );
  }
}
