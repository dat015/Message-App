import 'package:first_app/PlatformClient/config.dart';
import 'package:first_app/data/dto/login_response.dart';
import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/models/conversation.dart';
import 'package:first_app/data/models/participants.dart';
import 'package:first_app/data/repositories/Conversations_repo/conversations_repository.dart';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';
import 'package:first_app/data/repositories/Participants_Repo/participants_repo.dart';
import 'package:first_app/data/repositories/User_Repo/user_repo.dart';
import 'package:flutter/material.dart';

class HomeProvider with ChangeNotifier {
  final ConversationRepo _conversationRepo = ConversationRepo();
  final UserRepo _userRepo = UserRepo();
  final ParticipantsRepo _participantsRepo = ParticipantsRepo();
  WebSocketService? _webSocketService;
  List<Conversation> _conversations = [];
  Map<int, String> _userNames = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _fetchConversations(userId);
      _initializeWebSocket(userId);
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi khi khởi tạo: $e';
      print(_errorMessage);
    }
    notifyListeners();
  }

  Future<void> _fetchConversations(int userId) async {
    try {
      final conversations = await _conversationRepo.getConversations(userId);
      for (var conversation in conversations) {
        if (!conversation.isGroup && conversation.participants != null) {
          final otherParticipant = conversation.participants!.firstWhere(
            (p) => p.userId != userId,
            orElse: () => Participants(
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
      _conversations = conversations;
    } catch (e) {
      _errorMessage = 'Lỗi khi lấy danh sách cuộc trò chuyện: $e';
      print(_errorMessage);
      _conversations = [];
    }
    notifyListeners();
  }

  void _initializeWebSocket(int userId) {
    _webSocketService = WebSocketService(
      url: Config.baseUrlWS,
      onMessageReceived: (MessageWithAttachment message) {
        updateChatList(message);
      },
    );

    for (var conversation in _conversations) {
      if (conversation.id != null) {
        _webSocketService?.connect(userId, conversation.id!);
      }
    }
  }

  void updateChatList(MessageWithAttachment newMessage) {
    final targetChat = _conversations.firstWhere(
      (chat) => chat.id == newMessage.message.conversationId,
      orElse: () => Conversation(
        name: '',
        createdAt: DateTime.now(),
        isGroup: false,
      ),
    );

    if (targetChat.id != null) {
      targetChat.lastMessage = newMessage.message.content;
      targetChat.lastMessageTime = newMessage.message.createdAt;
      _conversations.remove(targetChat);
      _conversations.insert(0, targetChat);
    } else {
      Conversation newConversation = Conversation(
        id: newMessage.message.conversationId,
        name: 'Cuộc trò chuyện mới',
        createdAt: DateTime.now(),
        isGroup: false,
        lastMessage: newMessage.message.content,
        lastMessageTime: newMessage.message.createdAt,
      );
      _conversations.insert(0, newConversation);
    }
    notifyListeners();
  }

  Future<String> getUserName(int userId) async {
    if (_userNames.containsKey(userId)) {
      return _userNames[userId]!;
    }
    try {
      final response = await _userRepo.getUser(userId);
      final username = response.username ?? 'Không xác định';
      _userNames[userId] = username;
      notifyListeners();
      return username;
    } catch (e) {
      print("Lỗi khi lấy tên người dùng cho userId $userId: $e");
      return 'Không xác định';
    }
  }

  void disconnectWebSocket() {
    _webSocketService?.disconnect();
  }
}