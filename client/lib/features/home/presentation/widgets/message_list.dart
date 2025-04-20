import 'package:first_app/data/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'chat_bubble.dart';

class MessageList extends StatelessWidget {
  final ScrollController _scrollController = ScrollController();

  MessageList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);
    final messages = provider.messages; // messages là List<MessageWithAttachment>

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có tin nhắn nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Bắt đầu cuộc trò chuyện!',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final messageWithAttachment = messages[index];
        final showDate = index == 0 ||
            DateFormat('yyyy-MM-dd')
                .format(messageWithAttachment.message.createdAt) !=
                DateFormat('yyyy-MM-dd')
                    .format(messages[index - 1].message.createdAt);

        return Column(
          children: [
            if (showDate)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy')
                        .format(messageWithAttachment.message.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ),
            ChatBubble(
              messageWithAttachment: messageWithAttachment,
              currentUserId: provider.userId,
              participants: provider.participants,
            ),
          ],
        );
      },
    );
  }
}