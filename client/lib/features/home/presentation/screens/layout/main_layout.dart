import 'dart:typed_data';
import 'package:first_app/data/repositories/Friends_repo/friends_repo.dart';
import 'package:first_app/features/home/presentation/friends/bloc/friends_bloc.dart';
import 'package:first_app/features/home/presentation/friends/bloc/friends_event.dart';
import 'package:first_app/features/home/presentation/friends/bloc/friends_state.dart';
import 'package:first_app/features/routes/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainLayout extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final int currentUserId;
  final String currentUserName;
  final String userAvatar;
  final String email;
  final FriendsRepo friendsRepo;

  const MainLayout({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.currentUserId,
    required this.currentUserName,
    required this.userAvatar,
    required this.friendsRepo,
    required this.email,
  });

  void _handleNavigation(BuildContext context, int index) {
    onItemTapped(index);
  }

  void _showQrCodeDialog(BuildContext context) {
    final friendsBloc = context.read<FriendsBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocBuilder<FriendsBloc, FriendsState>(
        bloc: friendsBloc,
        builder: (context, state) {
          if (state is FriendsLoaded && state.qrCodeData != null) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Mã QR của bạn',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Image.memory(
                Uint8List.fromList(state.qrCodeData!),
                width: 200,
                height: 200,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Đóng'),
                ),
              ],
            );
          }
          return const AlertDialog(
            content: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 16,
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: CircleAvatar(
            backgroundImage: userAvatar.isNotEmpty ? NetworkImage(userAvatar) : null,
            child: userAvatar.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
            backgroundColor: userAvatar.isEmpty ? Colors.blueAccent : null,
          ),
        ),
        title: Text(
          selectedIndex == 0
              ? 'Đoạn chat'
              : selectedIndex == 1
                  ? 'Bạn bè'
                  : selectedIndex == 2
                      ? 'Bảng tin'
                      : selectedIndex == 3
                          ? 'Thông báo'
                          : 'Cá nhân',
          style: const TextStyle(
            color: Colors.blueAccent,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.blueAccent),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(
                  currentUserId: currentUserId,
                  friendsBloc: context.read<FriendsBloc>(),
                  friendsRepo: friendsRepo,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code, color: Colors.blueAccent),
            onPressed: () {
              context.read<FriendsBloc>().add(GenerateUserQrCodeEvent());
              _showQrCodeDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
            onPressed: () {
              NavigationHelper().goToQrScanner(
                context,
                context.read<FriendsBloc>(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.blueAccent),
            onPressed: () {
              NavigationHelper().goToSetting(
                context,
                email,
                context.read<FriendsBloc>(),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 5),
          ],
        ),
        margin: const EdgeInsets.only(top: 4),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: body,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Đoạn chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Bạn bè',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.post_add_outlined),
              activeIcon: Icon(Icons.post_add),
              label: 'Bảng tin',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none),
              activeIcon: Icon(Icons.notifications),
              label: 'Thông báo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
          ],
          currentIndex: selectedIndex,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          onTap: (index) => _handleNavigation(context, index),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 11,
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate<String> {
  final int currentUserId;
  final FriendsBloc friendsBloc;
  final FriendsRepo friendsRepo;

  CustomSearchDelegate({
    required this.currentUserId,
    required this.friendsBloc,
    required this.friendsRepo,
  });

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            friendsBloc.add(ResetSearchEvent());
          },
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          friendsBloc.add(ResetSearchEvent());
          close(context, '');
        },
      );

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) {
      friendsBloc.add(ResetSearchEvent());
      return const Center(child: Text('Nhập email để tìm kiếm'));
    }
    return BlocListener<FriendsBloc, FriendsState>(
      bloc: friendsBloc,
      listener: (context, state) {
        if (state is FriendsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: BlocBuilder<FriendsBloc, FriendsState>(
        bloc: friendsBloc,
        builder: (context, state) {
          if (state is FriendsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is FriendsSearchSuccess) {
            return RefreshIndicator(
              onRefresh: () async {
                if (query.isNotEmpty) {
                  friendsBloc.add(SearchUsersEvent(query));
                }
              },
              child: state.searchResults.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 60, color: Colors.grey),
                          Text('Không tìm thấy người dùng', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: state.searchResults.length,
                      itemBuilder: (context, index) {
                        final user = state.searchResults[index];
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['email'] ?? '',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                                if (user['mutualFriendsCount'] > 0)
                                  Text(
                                    '${user['mutualFriendsCount']} bạn chung',
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                              ],
                            ),
                            onTap: () => user['id'] != null
                                ? NavigationHelper().goToProfile(context, currentUserId, user['id'])
                                : null,
                            trailing: _buildActionButton(context, user, index),
                          ),
                        );
                      },
                    ),
            );
          } else if (state is FriendsError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text('Nhập email để tìm kiếm'));
        },
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, dynamic user, int index) {
    final status = user['relationshipStatus'] ?? 'None';
    print('Building action button for user: $user, status: $status');

    return switch (status) {
      'None' => ElevatedButton(
          onPressed: () {
            final receiverId = int.tryParse(user['id'].toString());
            if (receiverId == null || receiverId <= 0) {
              print('Invalid receiverId: ${user['id']}');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Không thể gửi lời mời: ID người dùng không hợp lệ')),
              );
              return;
            }
            print('Sending friend request to user ID: $receiverId');
            friendsBloc.add(
              SendFriendRequestEvent(
                receiverId,
                user['username'] ?? 'Unknown',
                user['avatar_url'] ?? '',
                index,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Thêm bạn', style: TextStyle(fontSize: 14, color: Colors.white)),
        ),
      'SentRequest' => Row(
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
              onPressed: () async {
                final receiverId = int.tryParse(user['id'].toString());
                if (receiverId == null || receiverId <= 0) {
                  print('Invalid receiverId: ${user['id']}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thể hủy: ID người dùng không hợp lệ')),
                  );
                  return;
                }
                try {
                  final sentRequests = await friendsRepo.getSentFriendRequests(currentUserId);
                  final request = sentRequests.firstWhere(
                    (req) => req.request.receiverId == receiverId,
                    orElse: () => throw Exception('No friend request found'),
                  );
                  final requestId = request.request.id;
                  print('Canceling friend request for user ID: $receiverId, requestId: $requestId');
                  friendsBloc.add(
                    CancelFriendRequestEvent(
                      requestId,
                      currentUserId,
                      receiverId,
                      user['username'] ?? 'Unknown',
                      index,
                    ),
                  );
                } catch (e) {
                  print('Error fetching requestId: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thể hủy: Lỗi khi lấy thông tin yêu cầu')),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Hủy', style: TextStyle(fontSize: 14, color: Colors.red)),
            ),
          ],
        ),
      'Friend' => ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Bạn bè', style: TextStyle(fontSize: 14, color: Colors.white)),
        ),
      'ReceivedRequest' => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                final senderId = int.tryParse(user['id'].toString());
                if (senderId == null || senderId <= 0) {
                  print('Invalid senderId: ${user['id']}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thể chấp nhận: ID người dùng không hợp lệ')),
                  );
                  return;
                }
                try {
                  final receivedRequests = await friendsRepo.getFriendRequests(currentUserId);
                  final request = receivedRequests.firstWhere(
                    (req) => req.request.senderId == senderId,
                    orElse: () => throw Exception('No friend request found'),
                  );
                  final requestId = request.request.id;
                  print('Accepting friend request from user ID: $senderId, requestId: $requestId');
                  friendsBloc.add(
                    AcceptFriendRequestEvent(
                      requestId,
                      user['username'] ?? 'Unknown',
                      index,
                    ),
                  );
                } catch (e) {
                  print('Error fetching requestId: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thể chấp nhận: Lỗi khi lấy thông tin yêu cầu')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Chấp nhận', style: TextStyle(fontSize: 14, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () async {
                final senderId = int.tryParse(user['id'].toString());
                if (senderId == null || senderId <= 0) {
                  print('Invalid senderId: ${user['id']}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thể từ chối: ID người dùng không hợp lệ')),
                  );
                  return;
                }
                try {
                  final receivedRequests = await friendsRepo.getFriendRequests(currentUserId);
                  final request = receivedRequests.firstWhere(
                    (req) => req.request.senderId == senderId,
                    orElse: () => throw Exception('No friend request found'),
                  );
                  final requestId = request.request.id;
                  print('Rejecting friend request from user ID: $senderId, requestId: $requestId');
                  friendsBloc.add(
                    RejectFriendRequestEvent(
                      requestId,
                      user['username'] ?? 'Unknown',
                      index,
                    ),
                  );
                } catch (e) {
                  print('Error fetching requestId: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thể từ chối: Lỗi khi lấy thông tin yêu cầu')),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Từ chối', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ),
          ],
        ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      friendsBloc.add(ResetSearchEvent());
    }
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Text(
        'Nhập email để tìm kiếm người dùng',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}