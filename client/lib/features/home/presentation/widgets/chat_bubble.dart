// ignore_for_file: unused_import

import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/models/messages.dart';
import 'package:first_app/data/models/participants.dart';
import 'package:first_app/data/providers/providers.dart';
import 'package:first_app/features/home/presentation/chat_box/full_screen_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final isSystemMessage = message.type == 'system'; // Kiểm tra loại tin nhắn

    if (isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildContent(context, isSentByMe),
          ),
        ),
      );
    }
    final sender = participants.firstWhere(
      (p) => p.user_id == message.senderId,
      orElse:
          () => Participants(
            id: 0,
            conversationId: message.conversationId,
            user_id: message.senderId,
            joinedAt: DateTime.now(),
            isDeleted: false,
          ),
    );

    return GestureDetector(
      onLongPress: () {
        _showContextMenu(context, message, isSentByMe);
      },
      child: Padding(
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
                backgroundImage:
                    sender.img_url != null
                        ? NetworkImage(sender.img_url!)
                        : null,
                child:
                    sender.img_url == null
                        ? const Icon(Icons.person, size: 20, color: Colors.grey)
                        : null,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  // Nếu tin nhắn bị thu hồi: bỏ màu nền, thêm viền
                  color:
                      message.isRecalled
                          ? Colors.transparent
                          : (isSentByMe ? Colors.blue : Colors.grey[100]),
                  border:
                      message.isRecalled
                          ? Border.all(
                            color: isSentByMe ? Colors.blue : Colors.grey[400]!,
                            width: 1,
                          )
                          : null,
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
                          sender.name!,
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
                            color:
                                isSentByMe && !message.isRecalled
                                    ? Colors.white70
                                    : Colors.grey[600],
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
                                    : (isSentByMe && !message.isRecalled
                                        ? Colors.white70
                                        : Colors.grey[600]),
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
                backgroundImage:
                    sender.img_url != null
                        ? NetworkImage(sender.img_url!)
                        : null,
                child:
                    sender.img_url == null
                        ? const Icon(Icons.person, size: 20, color: Colors.grey)
                        : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isSentByMe) {
    final message = messageWithAttachment.message;
    final attachment = messageWithAttachment.attachment;

    // Nếu tin nhắn bị thu hồi, hiển thị thông báo thay vì nội dung gốc
    if (message.isRecalled) {
      return Text(
        "Tin nhắn đã được thu hồi",
        style: TextStyle(
          color: isSentByMe ? Colors.blue : Colors.grey[600],
          fontSize: 15,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Nếu có attachment và fileUrl không null
    if (attachment != null && attachment.fileUrl != null) {
      final url = attachment.fileUrl!;

      // Kiểm tra xem có phải là ảnh không
      final isImage =
          attachment.fileType.startsWith('image/') ||
          (url.contains("res.cloudinary.com") &&
              url.contains("/image/upload")) ||
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
            placeholder:
                (context, url) => const SizedBox(
                  width: 150,
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                ),
            errorWidget:
                (context, url, error) => const SizedBox(
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
    final isUrl = urlRegExp.hasMatch(message.content ?? '');

    if (isUrl) {
      return GestureDetector(
        onTap: () async {
          final uri = Uri.parse(message.content ?? '');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể mở liên kết')),
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
                message.content ?? '',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 15,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Nhấn để xem nội dung',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Nếu không có attachment và không phải URL, hiển thị nội dung tin nhắn
    return Text(
      message.content ?? '',
      style: TextStyle(
        color: isSentByMe ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    MessageDTOForAttachment message,
    bool isSentByMe,
  ) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + renderBox.size.width,
        position.dy + renderBox.size.height,
      ),
      items: [
        const PopupMenuItem<String>(value: 'copy', child: Text('Sao chép')),
        const PopupMenuItem<String>(
          value: 'forward',
          child: Text('Chuyển tiếp'),
        ),
        if (isSentByMe)
          const PopupMenuItem<String>(value: 'delete', child: Text('Xóa')),
        const PopupMenuItem<String>(value: 'reply', child: Text('Trả lời')),
      ],
    ).then((value) {
      if (value != null) {
        _handleMenuSelection(context, value, message);
      }
    });
  }

  void _handleMenuSelection(
    BuildContext context,
    String value,
    MessageDTOForAttachment message,
  ) {
    switch (value) {
      case 'copy':
        Clipboard.setData(ClipboardData(text: message.content ?? ''));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã sao chép tin nhắn')));
        break;
      case 'forward':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Chuyển tiếp tin nhắn')));
        break;
      case 'delete':
        Provider.of<ChatProvider>(
          context,
          listen: false,
        ).deleteMessage(message.id ?? 0);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa tin nhắn')));
        break;
      case 'reply':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Trả lời tin nhắn')));
        break;
    }
  }
}
