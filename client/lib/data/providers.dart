import 'package:flutter/material.dart';
import 'package:first_app/data/models/messages.dart';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';
import 'package:first_app/data/repositories/Message_Repo/message_repository.dart';
import 'package:first_app/data/repositories/Conversations_repo/conversations_repository.dart';
import 'package:first_app/data/repositories/Participants_Repo/participants_repo.dart';
import 'package:first_app/data/models/conversation.dart';
import 'package:first_app/data/models/participants.dart';

class ChatProvider with ChangeNotifier {
  final MessageRepo _messageRepo = MessageRepo();
  final ConversationRepo _conversationRepo = ConversationRepo();
  final ParticipantsRepo _participantsRepo = ParticipantsRepo();
  late WebSocketService _webSocketService;

  List<Message> _messages = [];
  Conversation? _conversation;
  List<Participants> _participants = [];
  final int userId;
  final int conversationId;

  List<Message> get messages => _messages;
  Conversation? get conversation => _conversation;
  List<Participants> get participants => _participants;

  ChatProvider({required this.userId, required this.conversationId}) {
    _initializeWebSocket();
    _loadData();
  }

  void addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  void _initializeWebSocket() {
    _webSocketService = WebSocketService(
      url: 'ws://localhost:5053/ws',
      onMessageReceived: _onMessageReceived,
    );
    print('Initializing WebSocket for user $userId, conversation $conversationId');
    _webSocketService.connect(userId, conversationId);
  }

  Future<void> _loadData() async {
    print('Loading data for conversation $conversationId and user $userId');
    try {
      final fetchedMessages = await _messageRepo.getMessages(conversationId).catchError((e) {
        print('Failed to fetch messages: $e');
        return <Message>[];
      });
      final fetchedConversation = await _conversationRepo.getConversation(conversationId).catchError((e) {
        print('Failed to fetch conversation: $e');
        return null;
      });
      final fetchedParticipants = await _participantsRepo.getParticipants(conversationId).catchError((e) {
        print('Failed to fetch participants: $e');
        return <Participants>[];
      });

      _messages = fetchedMessages ?? [];
      _conversation = fetchedConversation;
      _participants = fetchedParticipants ?? [];
      notifyListeners();
    } catch (e) {
      print('Error loading data: $e');
      _messages = [];
      _conversation = null;
      _participants = [];
      notifyListeners();
    }
  }

  void _onMessageReceived(Message message) {
    print('Received message: ${message.toJson()}');
    if (message.conversationId != conversationId) {
      print('Received message for a different conversation: ${message.conversationId}');
      return;
    }

    _messages.add(message);
    notifyListeners();
  }

  void sendGroupMessage(String content) {
    print('Sending group message: $content');
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch, // ID tạm thời
      senderId: userId,
      content: content,
      createdAt: DateTime.now(),
      conversationId: conversationId,
      isRead: true,
    );
    
    _messages.add(newMessage);
    notifyListeners(); // 🚀 Cập nhật UI ngay
    _webSocketService.sendMessage(userId, conversationId, content);
  }

  void sendPrivateMessage(String content, int recipientId) {
    print('Sending private message to $recipientId: $content');
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch,
      senderId: userId,
      content: content,
      createdAt: DateTime.now(),
      conversationId: conversationId,
      isRead: true,
    );

    _messages.add(newMessage);
    notifyListeners(); // 🚀 Cập nhật UI ngay
    _webSocketService.sendPrivateMessage(userId, conversationId, recipientId, content);
  }

  void disconnect() {
    print('Disconnecting WebSocket');
    _webSocketService.disconnect();
  }
}
