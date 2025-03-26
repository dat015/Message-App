import 'dart:async';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:first_app/data/api/api_client.dart';

class SearchUsersScreen extends StatefulWidget {
  final List<dynamic> searchResults;
  final int currentUserId;

  const SearchUsersScreen({
    super.key,
    required this.searchResults,
    required this.currentUserId,
  });

  @override
  _SearchUsersScreenState createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  late WebSocketService _webSocketService;
  bool _isWebSocketConnected = false;
  late StreamSubscription _messageSubscription;
  late StreamSubscription _connectionSubscription;

  @override
  void initState() {
    super.initState();
    // Sử dụng singleton instance của WebSocketService
    _webSocketService = WebSocketService(
      userId: widget.currentUserId,
      url: 'ws://localhost:5053/ws',
      onMessageReceived: (message) {},
      onConnectionStateChanged: (isConnected) {},
    );
    // Kết nối chỉ được gọi một lần khi ứng dụng khởi động hoặc sau khi đăng xuất
    // Nếu đã kết nối rồi, không cần gọi lại
    if (!_webSocketService.isConnected) {
      _webSocketService.connect();
    }

    // Lắng nghe tin nhắn từ WebSocket
    _messageSubscription = _webSocketService.onMessage.listen((message) {
      if (message['Type'] == 'RequestAccepted' || message['Type'] == 'RequestRejected' || message['Type'] == 'RequestCancelled') {
        if (mounted) {
          setState(() {
            final receiverId = message['ReceiverId'];
            final senderId = message['SenderId'];
            for (var user in widget.searchResults) {
              if (user['id'] == receiverId || user['id'] == senderId) {
                user['relationshipStatus'] = message['Type'] == 'RequestAccepted'
                    ? 'Accepted'
                    : message['Type'] == 'RequestRejected'
                        ? 'Rejected'
                        : 'NotSent';
                break;
              }
            }
          });
        }
      }
    });

    // Lắng nghe trạng thái kết nối
    _connectionSubscription = _webSocketService.onConnectionState.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isWebSocketConnected = isConnected;
        });
      }
    });
  }

  Future<void> _sendFriendRequest(BuildContext context, int receiverId, String username, int index) async {
    final ApiClient apiService = ApiClient();
    try {
      final response = await apiService.post(
        'api/friends/send-request',
        data: {
          'senderId': widget.currentUserId,
          'receiverId': receiverId,
        },
      );
      if (mounted) {
        setState(() {
          widget.searchResults[index]['relationshipStatus'] = response['relationshipStatus'] ?? 'PendingSent';
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent to $username'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send friend request: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cancelFriendRequest(BuildContext context, int receiverId, String username, int index) async {
    final ApiClient apiService = ApiClient();
    try {
      await apiService.post(
        '/api/Friends/reject-request',
        data: {
          'senderId': widget.currentUserId,
          'receiverId': receiverId,
        },
      );
      if (mounted) {
        setState(() {
          widget.searchResults[index]['relationshipStatus'] = 'NotSent';
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request to $username cancelled'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel friend request: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Chỉ hủy subscription, không đóng kết nối WebSocket
    _messageSubscription.cancel();
    _connectionSubscription.cancel();
    super.dispose();
  }

  Widget _buildActionButton(BuildContext context, String status, dynamic user, int index) {
    switch (status) {
      case 'NotSent':
        return ElevatedButton(
          onPressed: () => _sendFriendRequest(context, user['id'], user['username'], index),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Thêm bạn bè',
            style: TextStyle(fontSize: 14),
          ),
        );
      case 'PendingSent':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Đã gửi',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _cancelFriendRequest(context, user['id'], user['username'], index),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Hủy yêu cầu',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        );
      case 'Accepted':
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Bạn bè',
            style: TextStyle(fontSize: 14),
          ),
        );
      case 'PendingReceived':
        return ElevatedButton(
          onPressed: () {
            // Logic chấp nhận yêu cầu (gọi API AcceptFriendRequestAsync)
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Chấp nhận',
            style: TextStyle(fontSize: 14),
          ),
        );
      case 'Rejected':
        return ElevatedButton(
          onPressed: () => _sendFriendRequest(context, user['id'], user['username'], index),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Thêm bạn bè',
            style: TextStyle(fontSize: 14),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kết quả tìm kiếm',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.searchResults.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Không tìm thấy người dùng',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: widget.searchResults.length,
                    itemBuilder: (context, index) {
                      final user = widget.searchResults[index];
                      final mutualFriends = user['mutualFriends'] ?? 0;
                      final relationshipStatus = user['relationshipStatus'] ?? 'NotSent';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12.0),
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(
                              user['avatar_url'] ?? 'https://via.placeholder.com/150',
                            ),
                            backgroundColor: Colors.grey[200],
                          ),
                          title: Text(
                            user['username'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (mutualFriends > 0)
                                Text(
                                  '$mutualFriends bạn chung',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          trailing: _buildActionButton(context, relationshipStatus, user, index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}