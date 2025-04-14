import 'package:first_app/data/models/conversation.dart';
import 'package:first_app/data/models/participants.dart';
import 'package:first_app/data/providers/providers.dart';
import 'package:first_app/features/home/presentation/screens/conversation_settings_screen.dart';
import 'package:first_app/features/home/presentation/widgets/message_input.dart';
import 'package:first_app/features/home/presentation/widgets/message_list.dart'
    show MessageList;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final int userId;
  final int? participantId; // nullable

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.userId,
    this.participantId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Conversation? _updatedConversation;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => ChatProvider(
            userId: widget.userId,
            conversationId: widget.conversationId,
          ),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, _updatedConversation);
            },
          ),
          title: Consumer<ChatProvider>(
            builder: (context, provider, child) {
              final conversation = provider.conversation;
              final participants =
                  provider.participants; // Get from provider directly

              if (conversation == null) return const Text('Đang tải...');

              print(
                "Conversation: isGroup=${conversation.isGroup}, name=${conversation.name}",
              );
              print("Current userId: ${widget.userId}");
              print(
                "Participants from provider: ${participants.map((p) => 'ID: ${p.id}, UserID: ${p.userId}, Name: ${p.name}').join(', ')}",
              );

              if (conversation.isGroup) {
                return Text(conversation.name);
              }

              // Tìm participant khác trong danh sách participants của provider
              final otherParticipant = participants.firstWhere(
                (p) => p.userId != widget.userId,
                orElse: () {
                  print("No other participant found");
                  return Participants(
                    id: 0,
                    conversationId: conversation.id ?? 0,
                    userId: 0,
                    joinedAt: DateTime.now(),
                    isDeleted: false,
                    name: conversation.name,
                  );
                },
              );

              print(
                "Selected participant: ID=${otherParticipant.id}, UserID=${otherParticipant.userId}, Name=${otherParticipant.name}",
              );

              // Trả về tên của participant khác
              return Text(otherParticipant.name ?? conversation.name);
            },
          ),
          backgroundColor: Colors.blue,
          actions: [
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: () {
                // TODO: Implement call functionality
              },
            ),
            Consumer<ChatProvider>(
              builder: (context, provider, child) {
                final conversation = provider.conversation;
                if (conversation == null) return const SizedBox.shrink();

                return IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () async {
                    final int id;
                    if (widget.participantId != null) {
                      print("Participant ID: ${widget.participantId}");
                      id = widget.participantId!;
                    } else {
                      id = widget.userId;
                    }
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ConversationSettingsScreen(
                              conversation: conversation,
                              currentUserId: id,
                            ),
                      ),
                    );

                    if (result == true) {
                      // User rời nhóm → thoát khỏi ChatScreen luôn
                      Navigator.pop(context);
                    } else if (result is Conversation) {
                      // Chỉ cập nhật tên → update provider và lưu lại để pop sau
                      Provider.of<ChatProvider>(
                        context,
                        listen: false,
                      ).updateConversation(result);

                      setState(() {
                        _updatedConversation = result;
                      });
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [Expanded(child: MessageList()), MessageInput()],
        ),
      ),
    );
  }
}
