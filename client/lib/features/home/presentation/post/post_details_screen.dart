import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_app/data/models/post.dart';
import 'package:first_app/features/home/presentation/diary/comment_screen.dart';
import 'package:flutter/material.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatar;

  const PostDetailScreen({
    Key? key,
    required this.postId,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Chi tiết bài viết'),
        elevation: 1,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('posts').doc(postId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Bài viết không tồn tại'));
          }

          final post = Post.fromMap(snapshot.data!.id, snapshot.data!.data() as Map<String, dynamic>);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card chứa toàn bộ bài viết
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(post.authorAvatar ?? ''),
                              radius: 24,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.authorName ?? 'Người dùng',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _formatTimeAgo(post.createdAt),
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                            )
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Nội dung bài viết
                        Text(
                          post.content ?? '',
                          style: const TextStyle(fontSize: 16, height: 1.4),
                        ),

                        const SizedBox(height: 12),

                        // Hình ảnh nếu có
                        if (post.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              post.imageUrl!,
                              fit: BoxFit.cover,
                              height: 250,
                              width: double.infinity,
                            ),
                          ),

                        const SizedBox(height: 16),
                        const Divider(),

                        // Like và nút bình luận
                        Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.red, size: 20),
                            const SizedBox(width: 6),
                            Text('${post.likes.length} lượt thích'),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CommentScreen(
                                    postId: postId,
                                    currentUserId: currentUserId,
                                    currentUserName: currentUserName,
                                    currentUserAvatar: currentUserAvatar,
                                    postContent: post.content ?? '',
                                    postImageUrl: post.imageUrl,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.comment_outlined),
                              label: const Text('Bình luận'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
