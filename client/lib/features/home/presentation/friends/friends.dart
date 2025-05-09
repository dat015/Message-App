import 'dart:typed_data';
import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/dto/friendrequest_withdetails.dart';
import 'package:first_app/data/models/friendsuggestion.dart';
import 'package:first_app/data/models/user.dart';
import 'package:first_app/features/routes/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/friends_bloc.dart';
import 'bloc/friends_event.dart';
import 'bloc/friends_state.dart';

class Friends extends StatelessWidget {
  final int currentUserId;

  const Friends({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return FriendsScreen(currentUserId: currentUserId);
  }
}

class FriendsScreen extends StatefulWidget {
  final int currentUserId;

  const FriendsScreen({super.key, required this.currentUserId});

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Tải dữ liệu ngay khi khởi tạo
    context.read<FriendsBloc>().add(LoadFriendsDataEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 6,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 6,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  ElevatedButton _buildStyledButton({
    required VoidCallback onPressed,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    Color? textColor,
    double elevation = 2,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: elevation,
      ),
      child: Text(label, style: TextStyle(color: textColor ?? Colors.white)),
    );
  }

  String _formatRequestTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.inDays == 0) {
      if (difference.inMinutes < 1) return 'Vừa xong';
      if (difference.inHours < 1) return '${difference.inMinutes} phút trước';
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks tuần trước';
    }
  }

  Widget _buildFriendRequestItem(
      BuildContext context, FriendRequestWithDetails item, int index, double screenWidth) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => NavigationHelper().goToProfile(context, widget.currentUserId, item.friend.senderId),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(item.friend.avatarUrl),
                onBackgroundImageError: (_, __) => const Icon(Icons.person, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => NavigationHelper().goToProfile(context, widget.currentUserId, item.friend.senderId),
                        child: Text(
                          item.friend.username,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        _formatRequestTime(item.request.createdAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (item.friend.mutualFriendsCount > 0)
                    Text(
                      '${item.friend.mutualFriendsCount} bạn chung',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildStyledButton(
                        onPressed: () => context
                            .read<FriendsBloc>()
                            .add(AcceptFriendRequestEvent(item.request.id, item.friend.username, index)),
                        label: 'Chấp nhận',
                        backgroundColor: Colors.blue[600]!,
                        foregroundColor: Colors.blue[800]!,
                      ),
                      const SizedBox(width: 8),
                      _buildStyledButton(
                        onPressed: () => context
                            .read<FriendsBloc>()
                            .add(RejectFriendRequestEvent(item.request.id, item.friend.username, index)),
                        label: 'Từ chối',
                        backgroundColor: Colors.grey[300]!,
                        foregroundColor: Colors.grey[500]!,
                        textColor: Colors.grey[800],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentFriendRequestItem(
      BuildContext context, FriendRequestWithDetails item, int index, double screenWidth) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => NavigationHelper().goToProfile(context, widget.currentUserId, item.friend.receiverId),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(item.friend.avatarUrl),
                onBackgroundImageError: (_, __) => const Icon(Icons.person, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            NavigationHelper().goToProfile(context, widget.currentUserId, item.friend.receiverId),
                        child: Text(
                          item.friend.username,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        _formatRequestTime(item.request.createdAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (item.friend.mutualFriendsCount > 0)
                    Text(
                      '${item.friend.mutualFriendsCount} bạn chung',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đang chờ xác nhận',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      _buildStyledButton(
                        onPressed: () => context.read<FriendsBloc>().add(CancelFriendRequestEvent(
                              item.request.id,
                              item.request.senderId,
                              item.request.receiverId,
                              item.friend.username,
                              index,
                            )),
                        label: 'Hủy',
                        backgroundColor: Colors.grey[300]!,
                        foregroundColor: Colors.grey[500]!,
                        textColor: Colors.grey[800],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendSuggestionItem(
      BuildContext context, FriendSuggestion suggestion, int index, double screenWidth) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => NavigationHelper().goToProfile(context, widget.currentUserId, suggestion.userId),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(suggestion.avatarUrl),
                onBackgroundImageError: (_, __) => const Icon(Icons.person, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => NavigationHelper().goToProfile(context, widget.currentUserId, suggestion.userId),
                    child: Text(
                      suggestion.username,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (suggestion.mutualFriendsCount > 0)
                    Text(
                      '${suggestion.mutualFriendsCount} bạn chung',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildStyledButton(
                      onPressed: () => context.read<FriendsBloc>().add(
                            SendFriendRequestEvent(suggestion.userId, suggestion.username, suggestion.avatarUrl, index),
                          ),
                      label: 'Thêm bạn',
                      backgroundColor: Colors.blue[600]!,
                      foregroundColor: Colors.blue[800]!,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendItem(BuildContext context, User friend, int index, double screenWidth) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => NavigationHelper().goToProfile(context, widget.currentUserId, friend.id),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(friend.avatarUrl),
                onBackgroundImageError: (_, __) => const Icon(Icons.person, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => NavigationHelper().goToProfile(context, widget.currentUserId, friend.id),
                    child: Text(
                      friend.username,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (friend.mutualFriendsCount > 0)
                    Text(
                      '${friend.mutualFriendsCount} bạn chung',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildStyledButton(
                      onPressed: () =>
                          context.read<FriendsBloc>().add(UnfriendEvent(friend.id, friend.username, index)),
                      label: 'Hủy kết bạn',
                      backgroundColor: Colors.red[600]!,
                      foregroundColor: Colors.red[800]!,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Gợi ý'),
            Tab(text: 'Lời mời'),
            Tab(text: 'Bạn bè'),
          ],
        ),
        Expanded(
          child: BlocConsumer<FriendsBloc, FriendsState>(
            listener: (context, state) {
              if (state is FriendsError) {
                _showErrorSnackBar(context, state.message);
              } else if (state is FriendsLoaded) {
                if (state.qrCodeData != null) {
                  _showSuccessSnackBar(context, 'Mã QR của bạn đã được tạo');
                }
                if (state.scannedUser != null) {
                  _showSuccessSnackBar(context, 'Đã quét: ${state.scannedUser!.username}');
                }
              }
            },
            builder: (context, state) {
              print('Building FriendsScreen with state: $state');
              if (state is FriendsLoading) {
                return const Center(child: CircularProgressIndicator(color: Colors.blue));
              } else if (state is FriendsError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => context.read<FriendsBloc>().add(LoadFriendsDataEvent()),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              } else if (state is FriendsLoaded) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    Container(
                      color: Colors.grey[100],
                      height: screenHeight,
                      child: state.friendSuggestions.isEmpty
                          ? _buildEmptyState('Không có gợi ý kết bạn')
                          : ListView.builder(
                              itemCount: state.friendSuggestions.length,
                              itemBuilder: (context, index) => _buildFriendSuggestionItem(
                                context,
                                state.friendSuggestions[index],
                                index,
                                screenHeight,
                              ),
                            ),
                    ),
                    Container(
                      color: Colors.grey[100],
                      height: screenHeight,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'Lời mời đã gửi (${state.sentFriendRequests.length})',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            state.sentFriendRequests.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Không có lời mời nào đã gửi',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: state.sentFriendRequests.length,
                                    itemBuilder: (context, index) => _buildSentFriendRequestItem(
                                      context,
                                      state.sentFriendRequests[index],
                                      index,
                                      screenHeight,
                                    ),
                                  ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'Lời mời đã nhận (${state.friendRequests.length})',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            state.friendRequests.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Không có lời mời nào',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: state.friendRequests.length,
                                    itemBuilder: (context, index) => _buildFriendRequestItem(
                                      context,
                                      state.friendRequests[index],
                                      index,
                                      screenHeight,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.grey[100],
                      height: screenHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Bạn bè (${state.friends.length})',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: state.friends.isEmpty
                                ? _buildEmptyState('Bạn chưa có bạn bè nào')
                                : ListView.builder(
                                    itemCount: state.friends.length,
                                    itemBuilder: (context, index) =>
                                        _buildFriendItem(context, state.friends[index], index, screenHeight),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              // Tự động tải dữ liệu nếu trạng thái không hợp lệ
              print('Unknown state, triggering LoadFriendsDataEvent');
              context.read<FriendsBloc>().add(LoadFriendsDataEvent());
              return const Center(child: CircularProgressIndicator(color: Colors.blue));
            },
          ),
        ),
      ],
    );
  }
}