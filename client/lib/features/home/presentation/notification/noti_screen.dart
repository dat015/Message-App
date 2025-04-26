import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_app/data/repositories/notification_repo/noti_repo.dart'; // Fix path case
import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  final String currentUserId;
  final NotiRepo _notiRepo = NotiRepo();

  NotificationScreen({super.key, required this.currentUserId});

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
            return Center(child: Text('Lỗi khi tải thông báo: ${snapshot.error}'));
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
              final name = noti['triggeredByName'];
              final content = type == 'like'
                  ? '$name đã thích bài viết của bạn'
                  : '$name đã bình luận: "${noti['commentContent'] ?? 'N/A'}"';
              final timestamp = (noti['createdAt'] as Timestamp?)?.toDate();

              return ListTile(
                leading: Icon(
                  type == 'like' ? Icons.favorite : Icons.comment,
                  color: isRead ? Colors.grey : Colors.red,
                ),
                title: Text(content),
                subtitle: Text(
                  timestamp != null
                      ? '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
                      : 'Unknown time',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: isRead ? null : const Icon(Icons.fiber_new, color: Colors.blue),
                onTap: () async {
                  try {
                    await _notiRepo.markAsRead(noti['id']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã đánh dấu là đã đọc')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}