import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/models/messages.dart';

class SearchMessagesScreen extends StatefulWidget {
  final int conversationId;
  final List<MessageWithAttachment> messages;

  const SearchMessagesScreen({
    super.key,
    required this.conversationId,
    required this.messages,
  });

  @override
  State<SearchMessagesScreen> createState() => _SearchMessagesScreenState();
}

class _SearchMessagesScreenState extends State<SearchMessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MessageWithAttachment> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  void _searchMessages(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isEmpty) {
        setState(() {
          _searchResults = [];
        });
        return;
      }

      setState(() => _isLoading = true);

      // Lọc tin nhắn cục bộ từ widget.messages
      final results = widget.messages
          .where((messageWithAttachment) {
            final content = messageWithAttachment.message.content?.toLowerCase() ?? '';
            final searchQuery = query.toLowerCase();
            return content.contains(searchQuery);
          })
          .toList(); // Giữ nguyên MessageWithAttachment, không dùng .map

      setState(() {
        _searchResults = results; // Không cần cast
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm tin nhắn'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tin nhắn...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    _searchMessages('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
              ),
              onChanged: _searchMessages,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy tin nhắn nào',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final messageWithAttachment = _searchResults[index];
                          final message = messageWithAttachment.message;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: const Icon(
                                  Icons.message,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                message.content ?? 'Không có nội dung',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${message.senderId} - ${DateFormat('dd/MM/yyyy HH:mm').format(message.createdAt ?? DateTime.now())}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              trailing: messageWithAttachment.attachment != null
                                  ? const Icon(Icons.attach_file)
                                  : null,
                              onTap: () {
                                // TODO: Điều hướng đến tin nhắn trong màn hình chat
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}