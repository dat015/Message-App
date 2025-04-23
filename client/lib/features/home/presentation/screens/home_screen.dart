import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/dto/login_response.dart';
import 'package:first_app/data/models/conversation.dart';
import 'package:first_app/data/repositories/Conversations_repo/conversations_repository.dart';
import 'package:first_app/data/repositories/Friends_repo/friends_repo.dart';
import 'package:first_app/features/home/presentation/diary/diary.dart';
import 'package:first_app/features/home/presentation/friends/bloc/friends_bloc.dart';
import 'package:first_app/features/home/presentation/friends/bloc/friends_event.dart';
import 'package:first_app/features/home/presentation/friends/friends.dart';
import 'package:first_app/features/home/presentation/users_profile/us_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  late String userAvatar;
  late String userName;
  ConversationRepo conversationRepo = ConversationRepo();

  @override
  void initState() {
    userId = widget.user.user!.id;
    userName = widget.user.user!.username;
    userAvatar = widget.user.user!.avatarUrl;
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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'Last message placeholder',
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
                    chat.createdAt.toString().substring(11, 16),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              onTap: () {
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

  // Hàm chọn nội dung body dựa trên selectedIndex
  Widget _getBodyContent() {
    switch (_selectedIndex) {
      case 0: // Đoạn chat
        return Column(children: [Expanded(child: _buildChatList())]);
      case 1: // Bạn bè
        return Friends(
          currentUserId: userId,
        );
      case 2: // Bảng tin
        return Diary(
          currentUserId: userId,
          currentUserName: widget.user.user!.username,
          userAvatar: widget.user.user!.avatarUrl,
        );
        case 4: // Trang cá nhân
      return ProfilePage(userId: userId, currentUserName: userName, userAvatar: userAvatar,);
      default:
        return const Center(child: Text('Chưa triển khai'));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsRepo = FriendsRepo();
    return BlocProvider(
      create: (context) => FriendsBloc(
        friendsRepo: FriendsRepo(),
        apiClient: ApiClient(),
        currentUserId: userId,
      )..add(LoadFriendsDataEvent()),
      child: MainLayout(
        body: _getBodyContent(),
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        currentUserId: userId,
        currentUserName: widget.user.user!.username,
        userAvatar: widget.user.user!.avatarUrl,
        friendsRepo: friendsRepo,
      )
    );
  }
}
