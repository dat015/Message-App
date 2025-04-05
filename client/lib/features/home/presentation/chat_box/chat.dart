import 'package:first_app/data/models/participants.dart';
import 'package:first_app/data/providers.dart';
import 'package:first_app/features/home/presentation/widgets/message_input.dart';
import 'package:first_app/features/home/presentation/widgets/message_list.dart'
    show MessageList;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatelessWidget {
  final int conversationId;
  final int userId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => ChatProvider(userId: userId, conversationId: conversationId),
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<ChatProvider>(
            builder: (context, provider, child) {
              final conversation = provider.conversation;
              if (conversation == null) return const Text('Loading...');
              if (conversation.isGroup) {
                return Text(conversation.name ?? 'Group Chat');
              } else {
                final participants = provider.participants;
                if (participants.isEmpty) return const Text('Chat');
                final other = participants.firstWhere(
                  (p) => p.userId != userId,
                  orElse:
                      () => Participants(
                        id: 0,
                        conversationId: conversationId,
                        userId: 0,
                        joinedAt: DateTime.now(),
                        isDeleted: false,
                      ),
                );
                return Text('User ${other.userId}');
              }
            },
          ),
          backgroundColor: Colors.blue,
        ),
        body: Column(
          children: [Expanded(child: MessageList()), MessageInput()],
        ),
      ),
    );
  }
}
