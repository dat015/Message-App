import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';
import 'bloc/search_bloc.dart';
import 'bloc/search_event.dart';
import 'bloc/search_state.dart';

class SearchUsersScreen extends StatelessWidget {
  final List<dynamic> searchResults;
  final int currentUserId;

  const SearchUsersScreen({
    super.key,
    required this.searchResults,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchUsersBloc(
        apiClient: ApiClient(),
        webSocketService: WebSocketService(
          userId: currentUserId,
          url: 'ws://localhost:5053/ws',
          onMessageReceived: (message) {},
          onConnectionStateChanged: (isConnected) {},
        ),
        currentUserId: currentUserId,
        initialSearchResults: searchResults,
      ),
      child: SearchUsersScreenContent(),
    );
  }
}

class SearchUsersScreenContent extends StatelessWidget {
  Widget _buildActionButton(BuildContext context, String status, dynamic user, int index) {
    switch (status) {
      case 'NotSent':
        return ElevatedButton(
          onPressed: () => context.read<SearchUsersBloc>().add(SendFriendRequestEvent(user['id'], user['username'], index)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: const Text('Thêm bạn bè', style: TextStyle(fontSize: 14)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text('Đã gửi', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => context.read<SearchUsersBloc>().add(CancelFriendRequestEvent(user['id'], user['username'], index)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Hủy yêu cầu', style: TextStyle(fontSize: 14)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: const Text('Bạn bè', style: TextStyle(fontSize: 14)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: const Text('Chấp nhận', style: TextStyle(fontSize: 14)),
        );
      case 'Rejected':
        return ElevatedButton(
          onPressed: () => context.read<SearchUsersBloc>().add(SendFriendRequestEvent(user['id'], user['username'], index)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: const Text('Thêm bạn bè', style: TextStyle(fontSize: 14)),
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<SearchUsersBloc, SearchUsersState>(
        listener: (context, state) {
          // Xử lý thông báo khi gửi/hủy lời mời
          if (state.searchResults.any((user) => user['relationshipStatus'] == 'PendingSent')) {
            final user = state.searchResults.firstWhere((u) => u['relationshipStatus'] == 'PendingSent');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Friend request sent to ${user['username']}'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state.searchResults.any((user) => user['relationshipStatus'] == 'NotSent' && user['id'] != null)) {
            final user = state.searchResults.firstWhere((u) => u['relationshipStatus'] == 'NotSent' && u['id'] != null);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Friend request to ${user['username']} cancelled'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: state.searchResults.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Không tìm thấy người dùng',
                              style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemCount: state.searchResults.length,
                        itemBuilder: (context, index) {
                          final user = state.searchResults[index];
                          final mutualFriends = user['mutualFriends'] ?? 0;
                          final relationshipStatus = user['relationshipStatus'] ?? 'NotSent';

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (mutualFriends > 0)
                                    Text(
                                      '$mutualFriends bạn chung',
                                      style: const TextStyle(fontSize: 14, color: Colors.grey),
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
          );
        },
      ),
    );
  }
}