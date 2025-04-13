import 'package:first_app/features/routes/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/friends_bloc.dart';
import 'bloc/friends_event.dart';

class SearchUsersScreen extends StatelessWidget {
  final List<dynamic> searchResults;
  final int currentUserId;
  final FriendsBloc friendsBloc; // Thêm FriendsBloc

  const SearchUsersScreen({
    super.key,
    required this.searchResults,
    required this.currentUserId,
    required this.friendsBloc, // Thêm vào constructor
  });

  Widget _buildActionButton(BuildContext context, dynamic user, int index) {
    final status = user['relationshipStatus'] ?? 'NotSent';

    return switch (status) {
      'NotSent' || 'Rejected' => ElevatedButton(
          onPressed: () => friendsBloc.add( // Sử dụng friendsBloc
                SendFriendRequestEvent(user['id'], user['username'], user['avatar_url'], index),
              ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Thêm bạn', style: TextStyle(fontSize: 14, color: Colors.white)),
        ),
      'PendingSent' => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Đã gửi', style: TextStyle(fontSize: 14, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => friendsBloc.add( // Sử dụng friendsBloc
                    CancelFriendRequestEvent(
                      user['requestId'] ?? 0,
                      currentUserId,
                      user['id'],
                      user['username'],
                      index,
                    ),
                  ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Hủy', style: TextStyle(fontSize: 14, color: Colors.red)),
            ),
          ],
        ),
      'Accepted' => ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Bạn bè', style: TextStyle(fontSize: 14, color: Colors.white)),
        ),
      'PendingReceived' => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => friendsBloc.add( // Sử dụng friendsBloc
                    AcceptFriendRequestEvent(user['requestId'], user['username'], index),
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Chấp nhận', style: TextStyle(fontSize: 14, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => friendsBloc.add( // Sử dụng friendsBloc
                    RejectFriendRequestEvent(user['requestId'], user['username'], index),
                  ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Từ chối', style: TextStyle(fontSize: 14, color: Colors.red)),
            ),
          ],
        ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        friendsBloc.add(ResetSearchEvent()); // Sử dụng friendsBloc
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kết quả tìm kiếm', style: TextStyle(color: Colors.white, fontSize: 20)),
          backgroundColor: Colors.blueAccent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              friendsBloc.add(ResetSearchEvent()); // Sử dụng friendsBloc
              Navigator.pop(context);
            },
          ),
        ),
        body: searchResults.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Không tìm thấy người dùng', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final user = searchResults[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: user['avatar_url']?.isNotEmpty == true
                            ? NetworkImage(user['avatar_url'])
                            : null,
                        child: user['avatar_url']?.isNotEmpty != true
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                      title: Text(
                        user['username'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: (user['mutualFriendsCount'] ?? 0) > 0
                          ? Text('${user['mutualFriendsCount']} bạn chung',
                              style: const TextStyle(fontSize: 14, color: Colors.grey))
                          : null,
                      onTap: () => user['id'] != null
                          ? NavigationHelper().goToProfile(context, currentUserId, user['id'])
                          : null,
                      trailing: _buildActionButton(context, user, index),
                    ),
                  );
                },
              ),
      ),
    );
  }
}