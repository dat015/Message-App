import 'package:first_app/data/models/post.dart';
import 'package:first_app/data/repositories/Post_repo/post_repo.dart';
import 'package:first_app/features/home/presentation/diary/create_post.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Diary extends StatefulWidget {
  final int currentUserId;
  final String currentUserName;

  const Diary({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(key: key);

  @override
  State<Diary> createState() => _DiaryState();
}

class _DiaryState extends State<Diary> {
  final PostRepo _postService = PostRepo();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.01,
                  ),
                  color: Colors.blue,
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.white),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: Text(
                          'Tìm kiếm',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: screenWidth * 0.045,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.01),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Colors.white,
                          size: screenWidth * 0.06,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: screenWidth * 0.07,
                          ),
                          Container(
                            padding: EdgeInsets.all(screenWidth * 0.01),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '5',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.025,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Today's status
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CreatePostScreen(
                                currentUserId: widget.currentUserId,
                                currentUserName: widget.currentUserName,
                              ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: screenWidth * 0.05,
                          backgroundImage: const AssetImage('/images/avt.jpg'),
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        Text(
                          'Hôm nay bạn thế nào?',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Media options
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Wrap(
                    spacing: screenWidth * 0.02,
                    runSpacing: screenHeight * 0.01,
                    children: [
                      _buildMediaOption(
                        Icons.image,
                        'Ảnh',
                        Colors.green,
                        screenWidth,
                      ),
                      _buildMediaOption(
                        Icons.videocam,
                        'Video',
                        Colors.purple,
                        screenWidth,
                      ),
                      _buildMediaOption(
                        Icons.photo_album,
                        'Album',
                        Colors.blue,
                        screenWidth,
                      ),
                      _buildMediaOption(
                        Icons.access_time,
                        'Kỷ niệm',
                        Colors.orange,
                        screenWidth,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // "Khoảnh khắc" section
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.01,
                  ),
                  child: Text(
                    'Khoảnh khắc',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Moments/Stories
                SizedBox(
                  height: screenHeight * 0.3,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                    ),
                    children: [
                      _buildStoryCard(
                        'Tạo mới',
                        '/images/avt.jpg',
                        isCreateNew: true,
                        width: screenWidth,
                        height: screenHeight,
                      ),
                      SizedBox(width: screenWidth * 0.025),
                      _buildStoryCard(
                        'Đức Quý',
                        '/images/illustration-3.png',
                        isCreateNew: false,
                        width: screenWidth,
                        height: screenHeight,
                      ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  thickness: 1,
                  color: const Color(0xFFEEEEEE),
                  indent: screenWidth * 0.04,
                  endIndent: screenWidth * 0.04,
                ),

                // Posts section
                // Thay thế phần StreamBuilder hiện tại
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('posts')
                          .where(
                            'authorId',
                            isEqualTo: widget.currentUserId.toString(),
                          )
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      // Kiểm tra nếu lỗi là do thiếu index
                      if (snapshot.error.toString().contains(
                        'The query requires an index',
                      )) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            child: const Text(
                              'Đang cấu hình hệ thống...\nVui lòng đợi trong giây lát và thử lại.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return Center(child: Text('Lỗi: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          child: const Text('Chưa có bài viết nào'),
                        ),
                      );
                    }

                    return Column(
                      children:
                          snapshot.data!.docs.map((doc) {
                            final postData = doc.data() as Map<String, dynamic>;
                            final post = Post.fromMap(doc.id, postData);

                            return _buildPostItem(
                              profileImage: '/images/loginill.png',
                              username: post.authorName ?? 'Unknown',
                              action: post.content ?? '',
                              timeAgo: _formatTimeAgo(post.createdAt),
                              postImage:
                                  post.imageUrl ?? '/images/register.png',
                              likeCount: 13,
                              commentCount: 1,
                              screenWidth: screenWidth,
                            );
                          }).toList(),
                    );
                  },
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

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} năm trước';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  Widget _buildMediaOption(
    IconData icon,
    String label,
    Color color,
    double screenWidth,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: screenWidth * 0.06),
          SizedBox(width: screenWidth * 0.02),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.035,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(
    String name,
    String imagePath, {
    required bool isCreateNew,
    required double width,
    required double height,
  }) {
    return Container(
      width: width * 0.4,
      height: height * 0.3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.03),
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(width * 0.03),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(width * 0.03),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCreateNew)
                  Container(
                    padding: EdgeInsets.all(width * 0.025),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.purple],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: width * 0.06,
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(width * 0.005),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: width * 0.04,
                      backgroundImage: const AssetImage('/images/apple.png'),
                    ),
                  ),
                SizedBox(height: width * 0.02),
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.04,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem({
    required String profileImage,
    required String username,
    required String action,
    required String timeAgo,
    required String postImage,
    required int likeCount,
    required int commentCount,
    required double screenWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Post header
        Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: screenWidth * 0.05,
                backgroundImage: AssetImage(profileImage),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth * 0.04,
                        ),
                        children: [
                          TextSpan(
                            text: username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ' $action'),
                        ],
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.more_horiz,
                color: Colors.grey[600],
                size: screenWidth * 0.06,
              ),
            ],
          ),
        ),

        // Post image
        Image.network(
          postImage,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => Image.asset(
                '/images/face.png',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
        ),

        // Post actions
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.02,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.thumb_up_alt_outlined,
                    color: Colors.grey,
                    size: screenWidth * 0.05,
                  ),
                  label: Text(
                    'Thích',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenWidth * 0.01,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: screenWidth * 0.05,
                        ),
                        Icon(
                          Icons.emoji_emotions,
                          color: Colors.amber,
                          size: screenWidth * 0.05,
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Text(
                          '$likeCount',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenWidth * 0.01,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.grey[600],
                          size: screenWidth * 0.05,
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Text(
                          '$commentCount',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
