import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/models/messages.dart';
import 'package:first_app/data/models/participants.dart';
import 'package:first_app/data/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageList extends StatelessWidget {
  final ScrollController _scrollController = ScrollController();

  MessageList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);
    final messages =
        provider.messages; // messages là List<MessageWithAttachment>

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
        final showDate =
            index == 0 ||
            DateFormat(
                  'yyyy-MM-dd',
                ).format(messageWithAttachment.message.createdAt) !=
                DateFormat(
                  'yyyy-MM-dd',
                ).format(messages[index - 1].message.createdAt);

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
                    DateFormat(
                      'dd/MM/yyyy',
                    ).format(messageWithAttachment.message.createdAt),
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

class ChatBubble extends StatelessWidget {
  final MessageWithAttachment messageWithAttachment;
  final int currentUserId;
  final List<Participants> participants;

  const ChatBubble({
    super.key,
    required this.messageWithAttachment,
    required this.currentUserId,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    final message = messageWithAttachment.message;
    final isSentByMe = message.senderId == currentUserId;
    final sender = participants.firstWhere(
      (p) => p.userId == message.senderId,
      orElse:
          () => Participants(
            id: 0,
            conversationId: message.conversationId,
            userId: message.senderId,
            joinedAt: DateTime.now(),
            isDeleted: false,
          ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: NetworkImage(
                'https://ui-avatars.com/api/?name=User+${sender.userId}&background=random',
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSentByMe ? Colors.blue : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft:
                      isSentByMe
                          ? const Radius.circular(20)
                          : const Radius.circular(0),
                  bottomRight:
                      isSentByMe
                          ? const Radius.circular(0)
                          : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isSentByMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                children: [
                  if (!isSentByMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'User ${sender.userId}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  _buildContent(context, isSentByMe),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isSentByMe ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      if (isSentByMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color:
                              message.isRead
                                  ? Colors.blue[100]
                                  : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isSentByMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: NetworkImage(
                'https://ui-avatars.com/api/?name=User+$currentUserId&background=random',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isSentByMe) {
  final attachment = messageWithAttachment.attachment;
  final messageContent = messageWithAttachment.message.content;

  // Nếu có attachment và fileUrl không null
  if (attachment != null && attachment.fileUrl != null) {
    final url = attachment.fileUrl!;

    // Kiểm tra xem có phải là ảnh không
    final isImage = 
        attachment.fileType.startsWith('image/') || 
        (url.contains("res.cloudinary.com") && url.contains("/image/upload")) ||
        url.toLowerCase().endsWith('.jpg') || 
        url.toLowerCase().endsWith('.jpeg') || 
        url.toLowerCase().endsWith('.png') || 
        url.toLowerCase().endsWith('.gif');

    if (isImage) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenImage(url: url),
            ),
          );
        },
        child: CachedNetworkImage(
          imageUrl: url,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox(
            width: 150,
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => const SizedBox(
            width: 150,
            height: 150,
            child: Icon(Icons.error, color: Colors.red),
          ),
        ),
      );
    }

    // Nếu không phải ảnh, hiển thị như file
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.attach_file,
          color: isSentByMe ? Colors.white : Colors.blue,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            "File: ${url.split('/').last}",
            style: TextStyle(
              color: isSentByMe ? Colors.white : Colors.blue,
              fontSize: 15,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  // Kiểm tra nếu nội dung tin nhắn là URL
  final urlRegExp = RegExp(
    r'^(https?:\/\/[^\s/$.?#].[^\s]*)',
    caseSensitive: false,
  );
  final isUrl = urlRegExp.hasMatch(messageContent);

  if (isUrl) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(messageContent);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể mở liên kết')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              messageContent,
              style: TextStyle(
                color: Colors.blue,
                fontSize: 15,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Nhấn để xem nội dung',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nếu không có attachment và không phải URL, hiển thị nội dung tin nhắn
  return Text(
    messageContent,
    style: TextStyle(
      color: isSentByMe ? Colors.white : Colors.black87,
      fontSize: 15,
    ),
  );
}
}

class FullScreenImage extends StatelessWidget {
  final String url;

  const FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ),
    );
  }
}