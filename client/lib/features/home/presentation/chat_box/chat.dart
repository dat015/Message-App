import 'dart:convert';
import 'package:first_app/data/dto/message_dto.dart';
import 'package:first_app/data/models/conversation.dart';
import 'package:first_app/data/models/messages.dart';
import 'package:first_app/data/models/participants.dart';
import 'package:first_app/data/repositories/Message_Repo/message_repository.dart';
import 'package:first_app/data/repositories/Conversations_repo/conversations_repository.dart';
import 'package:first_app/data/repositories/Participants_Repo/participants_repo.dart';
import 'package:flutter/material.dart';
import '../../../../data/repositories/Chat/websocket_service.dart';
import '../../../../data/repositories/User_Repo/user_repo.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final int user_id;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.user_id,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageRepo messageRepo = MessageRepo();
  final ConversationRepo conversationRepo = ConversationRepo();
  final ParticipantsRepo participantsRepo = ParticipantsRepo();
  final UserRepo userRepo = UserRepo();
  late WebSocketService _webSocketService;

  List<Message> messages = [];
  Conversation? conversation;
  List<Participants> participants = [];
  bool isTextFieldFocused = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late int currentUserId;

  @override
  void initState() {
    currentUserId = widget.user_id;
    super.initState();
    _loadData();
    _webSocketService = WebSocketService(
      url: 'ws://localhost:5053/ws',
      onMessageReceived: _onMessageReceived,
      user_id: currentUserId,
    );
    _webSocketService.connect();
  }

  Future<void> _loadData() async {
    try {
      final fetchedMessages = await messageRepo.getMessages(widget.conversationId).catchError((e) {
        print('Failed to fetch messages: $e');
        return <Message>[];
      });
      final fetchedConversation = await conversationRepo.getConversation(widget.conversationId).catchError((e) {
        print('Failed to fetch conversation: $e');
        return null;
      });
      final fetchedParticipants = await participantsRepo.getParticipants(widget.conversationId).catchError((e) {
        print('Failed to fetch participants: $e');
        return <Participants>[];
      });

      setState(() {
        messages = fetchedMessages ?? [];
        conversation = fetchedConversation;
        participants = fetchedParticipants ?? [];
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        messages = [];
        conversation = null;
        participants = [];
      });
    }
  }

  void _onMessageReceived(String message) {
    print('Received message: $message');
    try {
      final jsonMessage = jsonDecode(message) as Map<String, dynamic>;
      if (jsonMessage['sender_id'] == null || jsonMessage['message'] == null || jsonMessage['conversation_id'] == null) {
        print('Invalid message format: Missing required fields');
        return;
      }

      final receivedConversationId = int.parse(jsonMessage['conversation_id'].toString());
      if (receivedConversationId != widget.conversationId) {
        print('Received message for a different conversation: $receivedConversationId');
        return;
      }

      final newMessage = Message(
        id: 0,
        senderId: int.parse(jsonMessage['sender_id'].toString()),
        content: jsonMessage['message'].toString(),
        createdAt: jsonMessage['created_at'] != null
            ? DateTime.parse(jsonMessage['created_at'].toString())
            : DateTime.now(),
        conversationId: receivedConversationId,
        isRead: false,
      );

      setState(() {
        messages.add(newMessage);
        _scrollToBottom();
      });
    } catch (e) {
      print('Error parsing message: $e');
    }
  }

  void _sendMessage() {
    final text = _messageController.text;
    if (text.isNotEmpty && _webSocketService.isConnected) {
      _webSocketService.send({
        'session_id': _webSocketService.sessionId,
        'message': text,
        'sender_id': currentUserId.toString(),
        'conversation_id': widget.conversationId.toString(),
      });
      _messageController.clear();
    } else {
      print('Cannot send message: WebSocket is not fully connected');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String getChatTitle() {
    if (conversation == null) return 'Loading...';
    if (conversation!.isGroup) {
      return conversation!.name ?? 'Group Chat';
    } else {
      if (participants.isEmpty) return 'Chat';
      final otherParticipant = participants.firstWhere(
        (p) => p.userId != currentUserId,
        orElse: () => Participants(
          id: 0,
          conversationId: widget.conversationId,
          userId: 0,
          joinedAt: DateTime.now(),
          isDeleted: false,
        ),
      );
      return 'User ${otherParticipant.userId}';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _webSocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          getChatTitle(),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(
                        message: messages[index],
                        currentUserId: currentUserId,
                        participants: participants,
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[200],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            isTextFieldFocused = true;
                          });
                        },
                        onEditingComplete: () {
                          setState(() {
                            isTextFieldFocused = false;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
                if (!isTextFieldFocused)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.image, color: Colors.blue),
                          onPressed: () {
                            print('Nút gửi ảnh được nhấn');
                          },
                          tooltip: 'Gửi Ảnh',
                        ),
                        IconButton(
                          icon: const Icon(Icons.attach_file, color: Colors.blue),
                          onPressed: () {
                            print('Nút gửi file được nhấn');
                          },
                          tooltip: 'Gửi File',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final Message message;
  final int currentUserId;
  final List<Participants> participants;

  const ChatBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSentByMe = message.senderId == currentUserId;
    print('Message Sender ID: ${message.senderId}, Current User ID: $currentUserId, isSentByMe: $isSentByMe');

    final sender = participants.firstWhere(
      (p) => p.userId == message.senderId,
      orElse: () => Participants(
        id: 0,
        conversationId: message.conversationId,
        userId: message.senderId,
        joinedAt: DateTime.now(),
        isDeleted: false,
      ),
    );

    return Row(
      mainAxisAlignment: isSentByMe ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (isSentByMe) // Current user's avatar on the left
          CircleAvatar(
            backgroundImage: NetworkImage('https://example.com/avatar_$currentUserId.png'),
            radius: 15,
          ),
        const SizedBox(width: 8.0),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            decoration: BoxDecoration(
              color: isSentByMe ? Colors.blue[200] : Colors.grey[300],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isSentByMe ? Colors.black : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  message.createdAt.toString().substring(11, 16),
                  style: TextStyle(fontSize: 10.0, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        if (!isSentByMe) // Other user's avatar on the right
          CircleAvatar(
            backgroundImage: NetworkImage('https://example.com/avatar_${sender.userId}.png'),
            radius: 15,
          ),
      ],
    );
  }
}