import 'package:first_app/data/models/messages.dart';
import 'package:first_app/data/models/participants.dart';
import 'package:first_app/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class MessageList extends StatelessWidget {
  final ScrollController _scrollController = ScrollController();

  MessageList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);
    final messages = provider.messages;

    if (messages.isEmpty) {
      return const Center(child: Text('No messages yet'));
    }

    // Cuộn xuống cuối khi có tin nhắn mới
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ChatBubble(
          message: messages[index],
          currentUserId: provider.userId,
          participants: provider.participants,
        );
      },
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
    final isSentByMe = message.senderId == currentUserId;
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isSentByMe)
            CircleAvatar(
              backgroundImage: NetworkImage('https://example.com/avatar_${sender.userId}.png'),
              radius: 15,
            ),
          if (!isSentByMe) const SizedBox(width: 8.0),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isSentByMe ? Colors.blueAccent : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isSentByMe ? const Radius.circular(12) : const Radius.circular(0),
                  bottomRight: isSentByMe ? const Radius.circular(0) : const Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(color: isSentByMe ? Colors.white : Colors.black87),
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
          if (isSentByMe) const SizedBox(width: 8.0),
          if (isSentByMe)
            CircleAvatar(
              backgroundImage: NetworkImage('https://example.com/avatar_$currentUserId.png'),
              radius: 15,
            ),
        ],
      ),
    );
  }
}