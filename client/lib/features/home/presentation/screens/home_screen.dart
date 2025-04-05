import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/dto/login_response.dart';
import 'package:first_app/data/models/conversation.dart';
import 'package:first_app/data/repositories/Conversations_repo/conversations_repository.dart';
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
  late Future<List<Conversation>> _conversationsFuture;
  late int userId;
  ConversationRepo conversationRepo = ConversationRepo();

  @override
  void initState() {
    userId = widget.user.user!.id; // Lấy userId từ widget.user
    print('User ID: $userId');
    super.initState();
    _conversationsFuture = _fetchConversations();
  }

  Future<List<Conversation>> _fetchConversations() async {
    return await conversationRepo.getConversations(userId);
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
        ),
      ),
    );
  }

  List<Conversation> getListBoxChat(int userId) {
    // Có thể tái sử dụng _conversationsFuture nếu cần
    return [];
  }

  Widget _buildChatList() {
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

        final conversations = snapshot.data!;
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
                      'https://via.placeholder.com/150',
                    ), // Thay bằng avatar thực tế từ API
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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'Last message placeholder', // Cần thêm trường từ API nếu có (xem dưới)
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
                    chat.createdAt.toString().substring(11, 16), // Lấy giờ:phút
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  // Thêm logic hiển thị unread count nếu API trả về
                  // Ví dụ: nếu API trả về unread count trong Conversation
                  // if (chat.unread > 0) ...
                ],
              ),
              onTap: () {
                print('chat.id: ${chat.id}, kiểu: ${chat.id.runtimeType}');
                print('userId: $userId, kiểu: ${userId.runtimeType}');

                final int? finalConversationId =
                    chat.id != null
                        ? (chat.id is int
                            ? chat.id
                            : int.parse(chat.id.toString()))
                        : 0;
                final int finalUserId =
                    userId != null
                        ? (userId is int
                            ? userId
                            : int.parse(userId.toString()))
                        : 0;

                Navigator.pushNamed(
                  context,
                  AppRoutes.chat,
                  arguments: {
                    'conversationId': finalConversationId,
                    'user_id': finalUserId,
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
      body: Column(
        children: [_buildSearchBar(), Expanded(child: _buildChatList())],
      ),
    );
  }
}
