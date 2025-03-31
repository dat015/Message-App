import 'package:first_app/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({super.key});

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isTextFieldFocused = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);

    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
                  ),
                  onTap: () => setState(() => _isTextFieldFocused = true),
                  onEditingComplete: () => setState(() => _isTextFieldFocused = false),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    provider.sendGroupMessage(_controller.text.trim());
                    _controller.clear();
                  }
                },
              ),
              PopupMenuButton<int>(
                icon: const Icon(Icons.person),
                onSelected: (recipientId) {
                  if (_controller.text.trim().isNotEmpty) {
                    provider.sendPrivateMessage(_controller.text.trim(), recipientId);
                    _controller.clear();
                  }
                },
                itemBuilder: (context) => provider.participants
                    .where((p) => p.userId != provider.userId)
                    .map((p) => PopupMenuItem<int>(
                          value: p.userId,
                          child: Text('User ${p.userId}'),
                        ))
                    .toList(),
                tooltip: 'Send private message',
              ),
            ],
          ),
          if (!_isTextFieldFocused)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.image, color: Colors.blue),
                    onPressed: () => print('Nút gửi ảnh được nhấn'),
                    tooltip: 'Gửi Ảnh',
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.blue),
                    onPressed: () => print('Nút gửi file được nhấn'),
                    tooltip: 'Gửi File',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}