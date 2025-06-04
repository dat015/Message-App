import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_app/data/repositories/Notification_Repo/noti_repo.dart';
import 'package:first_app/features/routes/navigation_helper.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  final String currentUserId;
  final String currentUserAvatar;
  final String currentUserName;
  final NotiRepo _notiRepo = NotiRepo();

  NotificationScreen({super.key, required this.currentUserId, required this.currentUserAvatar, required this.currentUserName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notiRepo.getNotifications(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi khi tải thông báo: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Chưa có thông báo nào'));
          }

          final notifications = snapshot.data!;

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final noti = notifications[index];
              final isRead = noti['isRead'] ?? false;
              final type = noti['type'];
              final postId = noti['postId'] as String?;
              String name;
              String content;
              IconData icon;

              switch (type) {
                case 'like':
                  name = noti['likerName'] ?? 'Người dùng';
                  content = '$name đã thích bài viết của bạn';
                  icon = Icons.favorite;
                  break;
                case 'comment':
                  name = noti['commenterName'] ?? 'Người dùng';
                  content = '$name đã bình luận bài viết của bạn';
                  icon = Icons.comment;
                  break;
                case 'reply':
                  name = noti['replierName'] ?? 'Người dùng';
                  content = '$name đã trả lời bình luận của bạn';
                  icon = Icons.reply;
                  break;
                default:
                  name = 'Người dùng';
                  content = 'Thông báo không xác định';
                  icon = Icons.notifications;
              }

              final timestamp = (noti['createdAt'] as Timestamp?)?.toDate();

              return ListTile(
                leading: Icon(icon, color: isRead ? Colors.grey : Colors.red),
                title: Text(
                  content,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  _formatTimeAgo((noti['createdAt'] as Timestamp).toDate()),
                ),
                onTap: () async {
                  try {
                    // Đánh dấu thông báo là đã đọc
                    await _notiRepo.markAsRead(noti['id']);

                    if (postId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Không tìm thấy bài viết'),
                        ),
                      );
                      return;
                    }

                    // Kiểm tra bài viết tồn tại
                    final postDoc =
                        await FirebaseFirestore.instance
                            .collection('posts')
                            .doc(postId)
                            .get();
                    if (!postDoc.exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bài viết không tồn tại')),
                      );
                      return;
                    }

                    // Điều hướng đến PostDetailScreen
                    NavigationHelper().goToPostDetail(
                      context,
                      postId,
                      currentUserId,
                      currentUserName,
                      currentUserAvatar,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays} ngày trước';
    if (difference.inHours > 0) return '${difference.inHours} giờ trước';
    if (difference.inMinutes > 0) return '${difference.inMinutes} phút trước';
    return 'Vừa xong';
  }
}
