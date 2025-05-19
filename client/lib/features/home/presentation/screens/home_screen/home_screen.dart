import 'package:first_app/PlatformClient/config.dart';
import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/dto/friend_dto.dart';
import 'package:first_app/data/dto/login_response.dart';
import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/models/conversation.dart';
import 'package:first_app/data/models/participants.dart';
import 'package:first_app/data/models/user.dart';
import 'package:first_app/data/repositories/Conversations_repo/conversations_repository.dart';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';
import 'package:first_app/data/repositories/Friends_repo/friends_repo.dart';
import 'package:first_app/data/repositories/Participants_Repo/participants_repo.dart';
import 'package:first_app/data/repositories/User_Repo/user_repo.dart';
import 'package:first_app/features/home/presentation/diary/diary.dart';
import 'package:first_app/features/home/presentation/friends/bloc/friends_bloc.dart';
import 'package:first_app/features/home/presentation/friends/bloc/friends_event.dart';
import 'package:first_app/features/home/presentation/friends/friends.dart';
import 'package:first_app/features/home/presentation/users_profile/us_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../routes/routes.dart';
import '../layout/main_layout.dart';

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
  List<FriendDTO> _friends = []; // Danh sách để lưu bạn bè
  late int userId;
  ConversationRepo conversationRepo = ConversationRepo();
  ParticipantsRepo participantsRepo = ParticipantsRepo();
  FriendsRepo friendRepo = FriendsRepo();
  WebSocketService? _webSocketService;
  Map<int, String> userNames = {}; // Lưu trữ userId -> username
  late Conversation _new_conversation;
  late Future<List<Conversation>> _conversationsFuture;
  late String userAvatar;
  late String userName;
  late String email;
  late FriendsRepo friendsRepo;

  @override
  void initState() {
    super.initState();
    userId = widget.user.user!.id;
    userName = widget.user.user!.username;
    userAvatar = widget.user.user!.avatarUrl;
    email = widget.user.user!.email;
    friendsRepo = FriendsRepo();
    _conversationsFuture = _fetchConversations();
    _fetchFriends();
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    _webSocketService = WebSocketService(
      url: Config.baseUrlWS,
      onMessageReceived: (MessageWithAttachment message) {
        print("ok");
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

  Future<void> _fetchFriends() async {
    try {
      final friends = await friendRepo.getFriendsDTO(userId);
      setState(() {
        _friends = friends;
      });
    } catch (e) {
      print("Lỗi khi lấy danh sách bạn bè: $e");
    }
  }

  void removeConversation(int conversationId) {
    print("REMOVE $conversationId");
    setState(() {
      _conversations.removeWhere(
        (conversation) => conversation.id == conversationId,
      );
    });
  }

  Future<List<Conversation>> _fetchConversations() async {
    try {
      final conversations = await conversationRepo.getConversations(userId);
      final conversationFilter =
          conversations.where((c) => (c.lastMessageTime != null || c.lastMessage != null)).toList();

      print("Thanh cong");
      for (var conversation in conversations) {
        print(
          "Conversation ${conversation.id} isGroup: ${conversation.isGroup.runtimeType} - value: ${conversation.isGroup}",
        );
        if (!conversation.isGroup && conversation.participants != null) {
          final otherParticipant = conversation.participants!.firstWhere(
            (p) => p.user_id != userId,
            orElse:
                () => Participants(
                  id: 0,
                  conversationId: conversation.id ?? 0,
                  user_id: 0,
                  joinedAt: DateTime.now(),
                  isDeleted: false,
                  name: conversation.name,
                ),
          );
          conversation.name = otherParticipant.name ?? conversation.name;
          conversation.img_url = otherParticipant.img_url;
          print("Conversation ${conversation.id}: ${conversation.name}");
          print("Selected participant name: ${otherParticipant.name}");
        }
      }
      setState(() {
        _conversations = conversationFilter;
        _conversationsFuture = Future.value(conversationFilter);
      });
      return conversationFilter;
    } catch (e) {
      print("Error in _fetchConversations: $e");
      return [];
    }
  }

  String getNewName(String content) {
    if (content.startsWith("Đã đổi tên nhóm thành ")) {
      return content.replaceFirst("Đã đổi tên nhóm thành ", "");
    } else if (content.startsWith("Đã đổi tên bạn thành ")) {
      return content.replaceFirst("Đã đổi tên bạn thành ", "");
    } else if (content.startsWith("Đã đổi ảnh nhóm ")) {
      return content.replaceFirst("Đã đổi ảnh nhóm ", "");
    } else if (content.startsWith("Đã được thêm vào nhóm ")) {
      return content.replaceFirst("Đã được thêm vào nhóm ", "");
    } else if (content.startsWith("Đã được thêm vào nhóm")) {
      return content.replaceFirst("Đã được thêm vào nhóm", "");
    } else if (content.startsWith("Đã được thêm bạn ")) {
      return content.replaceFirst("Đã được thêm bạn ", "");
    } else if (content.startsWith("Đã được thêm bạn")) {
      return content.replaceFirst("Đã được thêm bạn", "");
    } else if (content.startsWith("Đã xóa khỏi nhóm ")) {
      return content.replaceFirst("Đã xóa khỏi nhóm ", "");
    } else if (content.startsWith("Đã rời khỏi nhóm")) {
      return content.replaceFirst("Đã rời khỏi nhóm", "");
    } else if (content.startsWith("Đã xóa bạn ")) {
      return content.replaceFirst("Đã xóa bạn ", "");
    } else if (content.startsWith("Đã xóa bạn")) {
      return content.replaceFirst("Đã xóa bạn", "");
    } else if (content.startsWith("Đã thêm bạn ")) {
      return content.replaceFirst("Đã thêm bạn ", "");
    } 
    
    return content;
  }

  Future<Conversation?> _fetchNewConversation(int conversationId) async {
    try {
      final conversation = await conversationRepo.getConversationDto(
        userId,
        conversationId,
      );
      if (conversation == null) {
        print("Không tìm thấy conversation $conversationId");
        return null;
      }
      print("Fetched conversation: $conversation");

      // Xử lý participants cho conversation 1:1
      if (!conversation.isGroup && conversation.participants != null) {
        final otherParticipant = conversation.participants!.firstWhere(
          (p) => p.user_id != userId,
          orElse:
              () => Participants(
                id: 0,
                conversationId: conversation.id ?? 0,
                user_id: 0,
                joinedAt: DateTime.now(),
                isDeleted: false,
                name: conversation.name,
              ),
        );
        conversation.name = otherParticipant.name ?? conversation.name;
        conversation.img_url = otherParticipant.img_url;
        // _webSocketService?.connect(userId, conversation.id!);
      }

      return conversation;
    } catch (e) {
      print("Lỗi khi lấy conversation $conversationId: $e");
      return null;
    }
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(time.year, time.month, time.day);

    if (messageDay == today) {
      return DateFormat('HH:mm').format(time);
    } else if (messageDay == today.subtract(Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }

  // Sử dụng trong code:
  void updateChatList(MessageWithAttachment newMessage) {
    if (newMessage.message.conversationId == null ||
        newMessage.message.content == null) {
      print("Invalid message received");
      return;
    }

    final conversationId = newMessage.message.conversationId!;
    final index = _conversations.indexWhere(
      (chat) => chat.id == conversationId,
    );

    setState(() {
      Conversation? conversation;

      // Nếu conversation đã tồn tại
      if (index != -1) {
        conversation = _conversations[index];
        _conversations.removeAt(index);
      } else {
        // Tạo conversation tạm thời nếu không tìm thấy
        conversation = Conversation(
          id: conversationId,
          name: 'Unknown',
          createdAt: newMessage.message.createdAt ?? DateTime.now(),
          isGroup: false, // Có thể cần kiểm tra thêm từ API
          lastMessage: newMessage.message.content,
          lastMessageTime: newMessage.message.createdAt,
        );
        // Gọi API để lấy thông tin conversation đầy đủ
        _fetchNewConversation(conversationId).then((newConversation) {
          if (newConversation != null) {
            print("new conversation $newConversation");
            setState(() {
              final idx = _conversations.indexWhere(
                (c) => c.id == conversationId,
              );
              if (idx != -1) {
                _conversations[idx] = newConversation;
              } else {
                _conversations.insert(0, newConversation);
              }
              print("Thêm hoặc cập nhật conversation mới: $conversationId");
            });
          }
        });
      }

      // Cập nhật thông tin conversation
      if (newMessage.message.type == "system") {
        conversation.lastMessage = newMessage.message.content;
        conversation.lastMessageSender = "Hệ thống";
        conversation.lastMessageTime = newMessage.message.createdAt;

        if (newMessage.message.content!.startsWith("Đã đổi tên nhóm thành ")) {
          conversation.name = getNewName(newMessage.message.content!);
        } else if (newMessage.message.content!.startsWith("Đã đổi ảnh nhóm ")) {
          final newImageUrl = getNewName(newMessage.message.content!);
          final urlRegExp = RegExp(
            r'^(https?:\/\/[^\s/$.?#].[^\s]*)$',
            caseSensitive: false,
          );
          if (urlRegExp.hasMatch(newImageUrl)) {
            conversation.img_url = newImageUrl;
          }
        }
      }
      else if(newMessage.message.content!.startsWith("Đã rời khỏi nhóm ")){
        removeConversation(conversationId);
        return;
      } else {
        // Tin nhắn thông thường
        conversation.lastMessage = newMessage.message.content;
        conversation.lastMessageSender =
            null; // Có thể lấy tên người gửi nếu cần
        conversation.lastMessageTime = newMessage.message.createdAt;
      }

      _conversations.insert(0, conversation);
      print("Cập nhật conversation: $conversationId");
    });
  }
  void _createNewGroup() {
    Navigator.pushNamed(
      context,
      AppRoutes.createGroup,
      arguments: {
        'userId': userId,
        'friends': _friends,
        'conversationRepo': conversationRepo,
        'webSocketService': _webSocketService,
        'selectedFriends' : _friends,
      },
    ).then((result) {
      if (result is Conversation) {
        setState(() {
          //  _conversations.insert(0, result);
        });
      }
    });
  }

  void _onItemTapped(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Widget _buildSearchBar() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: Colors.grey[200],
  //         borderRadius: BorderRadius.circular(30.0),
  //       ),
  //       child: TextFormField(
  //         decoration: InputDecoration(
  //           hintText: 'ìm kiếm',
  //           hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
  //           prefixIcon: const Icon(Icons.circle, color: Colors.blueAccent),
  //           border: InputBorder.none,
  //           contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
  //         ),
  //         onFieldSubmitted: (value) {},
  //       ),
  //     ),
  //   );
  // }



  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('Không tìm thấy bạn bè')),
      );
    }

    return SizedBox(
      height: 90,
      child: ClipRect(
        child: GridView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisSpacing: 12.0,
            childAspectRatio: 80 / 80, // Tỷ lệ 1:1
          ),
          itemCount: _friends.length,
          itemBuilder: (context, index) {
            final friend = _friends[index];
            if (friend.friendId == null) {
              return const SizedBox.shrink();
            }
            final displayName =
                friend.username != null && friend.username!.length > 15
                    ? '${friend.username!.substring(0, 12)}...'
                    : friend.username ?? 'Không xác định';
            return GestureDetector(
              onTap: () async {
                try {
                  final conversation = await conversationRepo.openConversation(
                    userId,
                    friend.friendId!,
                  );
                  var existingConversation = _conversations.firstWhere(
                    (c) => c.id == conversation.id,
                    orElse:
                        () => Conversation(
                          id: -1, // Use an invalid ID or a placeholder
                          name: '',
                          isGroup: false,
                          createdAt: DateTime.now(),
                          lastMessage: null,
                          lastMessageSender: null,
                          lastMessageTime: null,
                          img_url: null,
                          participants: [],
                        ), // Trả về null nếu không tìm thấy
                  );

                  // Nếu conversation chưa tồn tại, thêm vào danh sách và kết nối WebSocket
                  // if (existingConversation == null) {
                  //   // Kết nối WebSocket cho tất cả participants trong conversation
                  //   for (var participant in conversation.participants) {
                  //     _webSocketService?.connect(
                  //       participant.userId,
                  //       conversation.id,
                  //     );
                  //   }
                  // }

                  Navigator.pushNamed(
                    context,
                    AppRoutes.chat,
                    arguments: {
                      'conversationId': conversation.id,
                      'user_id': userId,
                      'participantId': friend.friendId,
                      'websocketService': _webSocketService,
                      'updateChatListCallback': updateChatList,
                      'onConversationRemoved': removeConversation,
                    },
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Không thể mở trò chuyện: $e')),
                  );
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                      friend.avatar ??
                          'https://thaka.bing.com/th?q=User+Avatar+Icon.png&w=120&h=120&c=1&rs=1&qlt=90&cb=1&dpr=1.5&pid=InlineBlock&mkt=en-WW&cc=VN&setlang=en&adlt=moderate&t=1&mw=247',
                    ),
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatList() {
    if (_conversations.isEmpty) {
      return FutureBuilder<List<Conversation>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No conversations found'));
          }

          // Cập nhật _conversations sau khi dữ liệu được tải
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _conversations = snapshot.data!;
            });
          });

          return _buildConversationListView(snapshot.data!);
        },
      );
    }

    return _buildConversationListView(_conversations);
  }

  Widget _buildConversationListView(List<Conversation> conversations) {
    if (conversations.isEmpty) {
      return const Center(child: Text('No conversations found'));
    }

    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final chat = conversations[index];
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
                  chat.img_url ??
                      'https://thaka.bing.com/th?q=Group+Avatar+Icon.png&w=120&h=120&c=1&rs=1&qlt=90&cb=1&dpr=1.5&pid=InlineBlock&mkt=en-WW&cc=VN&setlang=en&adlt=moderate&t=1&mw=247',
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
                _formatMessageTime(chat.lastMessageTime ?? chat.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          onTap: () async {
            final int? finalConversationId =
                chat.id != null
                    ? (chat.id is int ? chat.id : int.parse(chat.id.toString()))
                    : 0;
            final int finalUserId =
                userId is int ? userId : int.parse(userId.toString());
            int? participantId;

            if (!chat.isGroup && finalConversationId != 0) {
              print("Current User ID: $finalUserId");
              print("Conversation ID: $finalConversationId");

              if (chat.participants != null && chat.participants!.isNotEmpty) {
                final validParticipants =
                    chat.participants!
                        .where((p) => p.user_id != 0 && !p.isDeleted)
                        .toList();

                print(
                  "Valid Participants: ${validParticipants.map((p) => 'ID: ${p.id}, UserID: ${p.user_id}, Name: ${p.name}').join(', ')}",
                );

                final otherParticipant = validParticipants.firstWhere(
                  (p) => p.user_id != finalUserId,
                  orElse:
                      () => Participants(
                        id: 0,
                        conversationId: finalConversationId ?? 0,
                        user_id: 0,
                        joinedAt: DateTime.now(),
                        isDeleted: false,
                        name: '',
                      ),
                );

                print(
                  "Other Participant: ID=${otherParticipant.id}, UserID=${otherParticipant.user_id}, Name=${otherParticipant.name}",
                );

                if (otherParticipant.user_id != 0) {
                  participantId = otherParticipant.user_id;
                  print("Selected Participant ID: $participantId");
                } else {
                  print("No valid participant found, fetching from API...");
                  try {
                    final updatedParticipants = await ParticipantsRepo()
                        .getParticipants(finalConversationId ?? 0);
                    print(
                      "Fetched Participants: ${updatedParticipants.map((p) => 'ID: ${p.id}, UserID: ${p.user_id}, Name: ${p.name}').join(', ')}",
                    );
                    final updatedOtherParticipant = updatedParticipants
                        .firstWhere(
                          (p) =>
                              p.user_id != finalUserId &&
                              p.user_id != 0 &&
                              !p.isDeleted,
                          orElse:
                              () => Participants(
                                id: 0,
                                conversationId: finalConversationId ?? 0,
                                user_id: 0,
                                joinedAt: DateTime.now(),
                                isDeleted: false,
                                name: '',
                              ),
                        );
                    if (updatedOtherParticipant.user_id != 0) {
                      participantId = updatedOtherParticipant.user_id;
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
                print("No participants found, fetching from API...");
                try {
                  final updatedParticipants = await ParticipantsRepo()
                      .getParticipants(finalConversationId ?? 0);
                  print(
                    "Fetched Participants: ${updatedParticipants.map((p) => 'ID: ${p.id}, UserID: ${p.user_id}, Name: ${p.name}').join(', ')}",
                  );
                  final updatedOtherParticipant = updatedParticipants
                      .firstWhere(
                        (p) =>
                            p.user_id != finalUserId &&
                            p.user_id != 0 &&
                            !p.isDeleted,
                        orElse:
                            () => Participants(
                              id: 0,
                              conversationId: finalConversationId ?? 0,
                              user_id: 0,
                              joinedAt: DateTime.now(),
                              isDeleted: false,
                              name: '',
                            ),
                      );
                  if (updatedOtherParticipant.user_id != 0) {
                    participantId = updatedOtherParticipant.user_id;
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
                'websocketService': _webSocketService,
                'updateChatListCallback': updateChatList,
              },
            );

            if (result is Conversation) {
              setState(() {
                final index = _conversations.indexWhere(
                  (c) => c.id == result.id,
                );
                if (index != -1) {
                  _conversations[index] = result;
                } else {
                  _conversations.insert(0, result);
                }
              });
            }
          },
        );
      },
    );
  }

  Widget _getBodyContent() {
    switch (_selectedIndex) {
      case 0: // Đoạn chat
        return Column(children: [Expanded(child: _buildChatList())]);
      case 1: // Bạn bè
        return Friends(currentUserId: userId);
      case 2: // Bảng tin
        return Diary(
          currentUserId: userId,
          currentUserName: userName,
          userAvatar: userAvatar,
        );
      case 3: // Thông báo
        return const Center(child: Text('Tính năng đang được phát triển'));
      case 4: // Trang cá nhân
        return ProfilePage(
          userId: userId,
          currentUserName: userName,
          userAvatar: userAvatar,
        );
      default:
        return const Center(child: Text('Chưa triển khai'));
    }
  }

  @override
  void dispose() {
    _webSocketService?.disconnect();
    super.dispose();
  }

  @override
 Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FriendsBloc(
        friendsRepo: friendsRepo,
        apiClient: _apiService,
        currentUserId: userId,
      )..add(LoadFriendsDataEvent()),
      child: MainLayout(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        currentUserId: userId,
        currentUserName: userName,
        userAvatar: userAvatar,
        email: email,
        friendsRepo: friendsRepo,
        body: _selectedIndex == 0
            ? Stack(
                children: [
                  Column(
                    children: [
                      // _buildSearchBar(),
                      _buildFriendsList(),
                      Expanded(child: _buildChatList()),
                    ],
                  ),
                  Positioned(
                    bottom: 16.0,
                    left: 16.0,
                    child: FloatingActionButton(
                      onPressed: _friends.isEmpty ? null : _createNewGroup, // Vô hiệu hóa nếu không có bạn bè
                      tooltip: 'Tạo nhóm mới',
                      backgroundColor: _friends.isEmpty ? Colors.grey : Colors.blue,
                      mini: true,
                      elevation: 4.0,
                      child: const Icon(
                        Icons.group_add,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            : _getBodyContent(),
      ),
    );
  }
}
