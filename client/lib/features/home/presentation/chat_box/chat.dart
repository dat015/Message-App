import 'package:first_app/data/models/conversation.dart';
import 'package:first_app/data/models/participants.dart';
import 'package:first_app/data/providers/CallProvider.dart';
import 'package:first_app/data/providers/providers.dart';
import 'package:first_app/features/home/presentation/chat_box/conversation_settings_screen.dart';
import 'package:first_app/features/home/presentation/widgets/message_input.dart';
import 'package:first_app/features/home/presentation/widgets/message_list.dart'
    show MessageList;
import 'package:first_app/features/home/presentation/chat_box/call_screen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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
      create: (_) => ChatProvider(
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
              final participants = provider.participants;

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

              return Text(otherParticipant.name ?? conversation.name);
            },
          ),
          backgroundColor: Colors.blue,
          actions: [
            Consumer<CallProvider>(
              builder: (context, callProvider, child) {
                return IconButton(
                  icon: Icon(
                    callProvider.isCalling ? Icons.call_end : Icons.videocam,
                    color: callProvider.isCalling ? Colors.red : Colors.black,
                  ),
                  onPressed: () async {
                    try {
                      if (callProvider.isCalling) {
                        print("Ending call");
                        callProvider.endCall();
                      } else {
                        final permissionStatus = await [
                          Permission.microphone,
                          Permission.camera,
                        ].request();
                        if (permissionStatus[Permission.microphone]!.isGranted &&
                            permissionStatus[Permission.camera]!.isGranted) {
                          String name = Provider.of<ChatProvider>(
                            context,
                            listen: false,
                          ).conversation!.name;
                          await callProvider.startCall(
                            widget.userId,
                            widget.conversationId,
                            name,
                            'video', // Sử dụng 'video' thay vì 'voice' để hỗ trợ video call
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Cần cấp quyền micro và camera để thực hiện cuộc gọi'),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      print('Error during call: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi khi thực hiện cuộc gọi: $e'),
                        ),
                      );
                    }
                  },
                  tooltip:
                      callProvider.isCalling ? 'Kết thúc cuộc gọi' : 'Gọi video',
                );
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
                        builder: (context) => ConversationSettingsScreen(
                          conversation: conversation,
                          currentUserId: id,
                          messages: provider.messages,
                        ),
                      ),
                    );

                    if (result == true) {
                      Navigator.pop(context);
                    } else if (result is Conversation) {
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
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(child: MessageList()),
                MessageInput(),
              ],
            ),
            Consumer<CallProvider>(
              builder: (context, callProvider, child) {
                print('CallProvider state: isCalling=${callProvider.isCalling}, '
                    'localRenderer=${callProvider.localRenderer != null}, '
                    'remoteRenderer=${callProvider.remoteRenderer != null}');
                if (callProvider.isCalling &&
                    callProvider.localRenderer != null &&
                    callProvider.remoteRenderer != null) {
                  return const CallScreen();
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}