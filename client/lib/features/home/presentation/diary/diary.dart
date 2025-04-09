import 'package:first_app/data/models/post.dart';
import 'package:first_app/data/models/story.dart'; // Thêm import cho Story
import 'package:first_app/data/repositories/Post_repo/post_repo.dart';
import 'package:first_app/data/repositories/Story_repo/story_repo.dart'; // Thêm import cho StoryRepository
import 'package:first_app/features/home/presentation/diary/create_post.dart';
import 'package:first_app/features/home/presentation/diary/comment_screen.dart';
import 'package:first_app/features/home/presentation/story/create_story_screen.dart'; // Thêm import cho CreateStoryScreen
import 'package:first_app/features/home/presentation/story/story_screen.dart'; // Thêm import cho StoryScreen
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Diary extends StatefulWidget {
  final int currentUserId;
  final String currentUserName;
  final String userAvatar;

  const Diary({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
    required this.userAvatar,
  }) : super(key: key);

  @override
  State<Diary> createState() => _DiaryState();
}

class _DiaryState extends State<Diary> {
  final PostRepo _postService = PostRepo();
  final StoryRepository _storyRepo = StoryRepository(); // Khởi tạo StoryRepository

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
                          builder: (context) => CreatePostScreen(
                            currentUserId: widget.currentUserId,
                            currentUserName: widget.currentUserName,
                            currentUserAvatar: widget.userAvatar,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: screenWidth * 0.05,
                          backgroundImage: NetworkImage(widget.userAvatar),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Khoảnh khắc',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StreamBuilder<List<Story>>(
                                stream: _storyRepo.getAllStories(widget.currentUserId.toString()),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                                  }
                                  if (!snapshot.hasData) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  final stories = snapshot.data!;
                                  print('Stories in "Xem tất cả": ${stories.length}');
                                  if (stories.isEmpty) {
                                    return const Center(child: Text('Không có story nào'));
                                  }
                                  return StoryScreen(
                                    currentUserId: widget.currentUserId.toString(),
                                    stories: stories,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Xem tất cả',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Moments/Stories
                SizedBox(
                  height: screenHeight * 0.3,
                  child: StreamBuilder<List<Story>>(
                    stream: _storyRepo.getAllStories(widget.currentUserId.toString()),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Lỗi: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final stories = snapshot.data!;
                      if (stories.isEmpty) {
                        return ListView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                          children: [
                            _buildStoryCard(
                              'Tạo mới',
                              '/images/avt.jpg',
                              isCreateNew: true,
                              width: screenWidth,
                              height: screenHeight,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateStoryScreen(
                                      currentUserId: widget.currentUserId.toString(),
                                      currentUserName: widget.currentUserName,
                                      currentUserAvatar: widget.userAvatar,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      }

                      return ListView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                        children: [
                          _buildStoryCard(
                            'Tạo mới',
                              widget.userAvatar,
                            isCreateNew: true,
                            width: screenWidth,
                            height: screenHeight,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateStoryScreen(
                                    currentUserId: widget.currentUserId.toString(),
                                    currentUserName: widget.currentUserName,
                                    currentUserAvatar: widget.userAvatar,
                                  ),
                                ),
                              );
                            },
                          ),
                          ...stories.map((story) => Padding(
                                padding: EdgeInsets.only(left: screenWidth * 0.025),
                                child: _buildStoryCard(
                                  story.authorName,
                                  story.isImage ? story.imageUrl! : '/images/illustration-3.png',
                                  isCreateNew: false,
                                  width: screenWidth,
                                  height: screenHeight,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StoryScreen(
                                          currentUserId: widget.currentUserId.toString(),
                                          stories: [story],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )).toList(),
                        ],
                      );
                    },
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
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where(
                        'authorId',
                        isEqualTo: widget.currentUserId.toString(),
                      )
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
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
                      children: snapshot.data!.docs.map((doc) {
                        final postData = doc.data() as Map<String, dynamic>;
                        final post = Post.fromMap(doc.id, postData);

                        return _buildPostItem(
                          profileImage: widget.userAvatar,
                          username: post.authorName ?? 'Unknown',
                          timeAgo: _formatTimeAgo(post.createdAt),
                          action: post.content ?? '',
                          postImage: post.imageUrl ?? '/images/register.png',
                          likeCount: 13,
                          commentCount: 1,
                          screenWidth: screenWidth,
                          postId: doc.id,
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
    required VoidCallback onTap, // Thêm callback để xử lý onTap
  }) {
    return GestureDetector(
      onTap: onTap, // Sử dụng callback để điều hướng
      child: Container(
        width: width * 0.4,
        height: height * 0.3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * 0.03),
          image: DecorationImage(image: NetworkImage(imagePath), fit: BoxFit.cover),
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
                        backgroundImage: NetworkImage(widget.userAvatar),
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
    required String postId,
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
                backgroundImage: NetworkImage(profileImage),
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
        if (postImage != '/images/register.png')
          Image.network(
            postImage,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              '/images/face.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

        // Post actions
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.02,
          ),
          child: Row(
            children: [
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    final post = Post.fromMap(
                      postId,
                      snapshot.data!.data() as Map<String, dynamic>,
                    );
                    final isLiked = post.likes.contains(
                      widget.currentUserId.toString(),
                    );

                    return TextButton.icon(
                      onPressed: () async {
                        try {
                          await _postService.toggleLike(
                            postId,
                            widget.currentUserId.toString(),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: $e')),
                          );
                        }
                      },
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                        size: screenWidth * 0.05,
                      ),
                      label: Text(
                        '${post.likes.length}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    );
                  },
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommentScreen(
                        postId: postId,
                        currentUserId: widget.currentUserId.toString(),
                        currentUserName: widget.currentUserName,
                        currentUserAvatar: widget.userAvatar,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.grey[600],
                  size: screenWidth * 0.05,
                ),
                label: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('comments')
                      .where('postId', isEqualTo: postId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final commentCount =
                        snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Text(
                      '$commentCount',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: screenWidth * 0.035,
                      ),
                    );
                  },
                ),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ],
          ),
        ),
      ],
    );
  }
}