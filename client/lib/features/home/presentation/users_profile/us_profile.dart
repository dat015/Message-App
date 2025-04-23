import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/models/post.dart';
import 'package:first_app/data/models/user_profile.dart';
import 'package:first_app/data/repositories/Chat/User_Profile_repo/us_profile_repository.dart';
import 'package:first_app/data/repositories/Post_repo/post_repo.dart';
import 'package:first_app/features/routes/navigation_helper.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  final String currentUserName;
  final String userAvatar;

  ProfilePage({
    required this.userId,
    required this.currentUserName,
    required this.userAvatar,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserProfile> userProfileFuture;
  final UsProfileRepository _usProfileRepository = UsProfileRepository();
  final PostRepo _postService = PostRepo();

  // Ánh xạ sở thích với icon
  final Map<String, IconData> _interestIcons = {
    'Đọc sách': Icons.book,
    'Du lịch': Icons.flight_takeoff,
    'Nấu ăn': Icons.kitchen,
    'Chơi thể thao': Icons.sports_soccer,
    'Nghe nhạc': Icons.headphones,
    'Xem phim': Icons.movie,
    'Vẽ tranh': Icons.brush,
    'Chụp ảnh': Icons.camera_alt,
    'Viết lách': Icons.edit,
    'Học ngoại ngữ': Icons.language,
    'Chơi game': Icons.videogame_asset,
    'Tập yoga': Icons.self_improvement,
    'Chạy bộ': Icons.directions_run,
    'Đạp xe': Icons.directions_bike,
    'Bơi lội': Icons.pool,
    'Cắm trại': Icons.local_fire_department,
    'Leo núi': Icons.terrain,
    'Thiền': Icons.spa,
    'Làm đồ thủ công': Icons.handyman,
    'Sưu tầm đồ vật': Icons.collections,
    'Xem bóng đá': Icons.sports_football,
    'Chơi nhạc cụ': Icons.music_note,
    'Tham gia tình nguyện': Icons.volunteer_activism,
    'Khám phá công nghệ': Icons.computer,
    'Làm vườn': Icons.local_florist,
    'Thử món ăn mới': Icons.restaurant,
    'Khác': Icons.interests,
  };

  @override
  void initState() {
    super.initState();
    userProfileFuture = _usProfileRepository.fetchUserProfile(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<UserProfile>(
          future: userProfileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Đã xảy ra lỗi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasData) {
              final user = snapshot.data!;
              return CustomScrollView(
                slivers: [
                  // Profile Header với ảnh bìa và ảnh đại diện
                  SliverAppBar(
                    expandedHeight: 250.0,
                    automaticallyImplyLeading: false,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.black26,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        user.username,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            'https://picsum.photos/800/600',
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            bottom: 50,
                            left: 16,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    child: ClipOval(
                                      child: Image.network(
                                        user.avatarUrl ??
                                            'https://picsum.photos/200',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(Icons.person, size: 50),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      height: 36,
                                      width: 36,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          Icons.camera_alt,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Tính năng thay đổi ảnh đại diện sẽ được cập nhật sau',
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Nội dung bên dưới
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 8),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Giới thiệu',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      NavigationHelper().goToEditProfile(
                                        context,
                                        user,
                                        (updatedUser) {
                                          setState(() {
                                            userProfileFuture = Future.value(
                                              updatedUser,
                                            );
                                          });
                                        },
                                      );
                                    },
                                    icon: Icon(Icons.edit, size: 20),
                                    label: Text('Chỉnh sửa'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[200],
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Text(
                                  user.bio ??
                                      'Hãy tạo bài viết đầu tiên của bạn\nHy vọng biết được thông tin của bạn',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              if (user.location != null)
                                _buildInfoRow(
                                  Icons.location_on,
                                  'Sống tại: ${user.location}',
                                ),
                              _buildInfoRow(
                                Icons.cake,
                                'Sinh ngày: ${_formatBirthday(user.birthday)}',
                              ),
                              _buildInfoRow(
                                user.gender ? Icons.male : Icons.female,
                                'Giới tính: ${user.gender ? "Nam" : "Nữ"}',
                              ),
                              if (user.interests != null &&
                                  user.interests!.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.favorite,
                                            color:
                                                Theme.of(context).primaryColor,
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Text(
                                          'Sở thích',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8.0,
                                      runSpacing: 4.0,
                                      children:
                                          user.interests!
                                              .split(',')
                                              .map(
                                                (interest) => Chip(
                                                  avatar: Icon(
                                                    _interestIcons[interest] ??
                                                        Icons.interests,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).primaryColor,
                                                    size: 18,
                                                  ),
                                                  label: Text(interest),
                                                  backgroundColor: Theme.of(
                                                    context,
                                                  ).primaryColor.withOpacity(
                                                    0.1,
                                                  ),
                                                  labelStyle: TextStyle(
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).primaryColor,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(
                          height: 1,
                          thickness: 6,
                          color: Color(0xFFF5F5F5),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Bài viết của bạn',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Posts List
                  StreamBuilder<List<Post>>(
                    stream: Stream.fromFuture(
                      _postService.getPostsByUserId(widget.userId.toString()),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return SliverToBoxAdapter(
                          child: Center(child: Text('Lỗi: ${snapshot.error}')),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.article_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Chưa có bài viết nào',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      NavigationHelper().goToCreatePost(
                                        context,
                                        widget.userId,
                                        user.username,
                                        user.avatarUrl ??
                                            'https://picsum.photos/200',
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Tạo bài viết mới'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final post = snapshot.data![index];
                          return _buildPostItem(
                            profileImage:
                                user.avatarUrl ?? 'https://picsum.photos/200',
                            username: user.username,
                            content: post.content ?? '',
                            timeAgo: _formatTimeAgo(post.createdAt),
                            postImage: post.imageUrl ?? '/images/register.png',
                            postId: post.id!,
                            post: post,
                          );
                        }, childCount: snapshot.data!.length),
                      );
                    },
                  ),
                ],
              );
            }
            return Container();
          },
        ),
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

  String _formatBirthday(String birthday) {
    // Giả sử birthday có định dạng "yyyy-MM-dd"
    final parts = birthday.split('-');
    if (parts.length != 3) {
      return birthday; // Trả về nguyên gốc nếu không đúng định dạng
    }

    final day = int.parse(parts[2]);
    final month = int.parse(parts[1]);
    final year = parts[0];

    // Chuyển đổi tháng thành dạng chữ
    final monthNames = [
      'tháng 1',
      'tháng 2',
      'tháng 3',
      'tháng 4',
      'tháng 5',
      'tháng 6',
      'tháng 7',
      'tháng 8',
      'tháng 9',
      'tháng 10',
      'tháng 11',
      'tháng 12',
    ];

    return '$day ${monthNames[month - 1]}, $year';
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 28),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xóa bài viết'),
            content: const Text('Bạn có chắc muốn xóa bài viết này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _postService.deletePost(postId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa bài viết thành công')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Widget _buildPostItem({
    required String profileImage,
    required String username,
    required String content,
    required String timeAgo,
    required String postImage,
    required String postId,
    required Post post,
  }) {
    final isOwnPost = post.authorId.toString() == widget.userId.toString();
    final authorAvatars = post.authorAvatar;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(authorAvatars),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwnPost)
                  IconButton(
                    icon: Icon(Icons.more_horiz, color: Colors.grey.shade600),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder:
                            (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit),
                                  title: const Text('Chỉnh sửa bài viết'),
                                  onTap: () {
                                    NavigationHelper().pop(
                                      context,
                                    ); // Đóng bottom sheet
                                    NavigationHelper().goToEditPost(
                                      context,
                                      post,
                                      widget.userId.toString(),
                                      widget.currentUserName,
                                      widget.userAvatar,
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: const Text(
                                    'Xóa bài viết',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onTap: () {
                                    NavigationHelper().pop(
                                      context,
                                    ); // Đóng bottom sheet
                                    _deletePost(postId);
                                  },
                                ),
                              ],
                            ),
                      );
                    },
                  ),
              ],
            ),
          ),
          // Post content
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(content, style: const TextStyle(fontSize: 16)),
            ),
          // Post image
          if (postImage != '/images/register.png')
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 400),
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Image.network(
                  postImage,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Image.asset('/images/face.png', fit: BoxFit.cover),
                ),
              ),
            ),
          // Post actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('posts')
                            .doc(postId)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const SizedBox();
                      }

                      final postData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final post = Post.fromMap(postId, postData);
                      final isLiked = post.likes.contains(
                        widget.userId.toString(),
                      );

                      return TextButton.icon(
                        onPressed: () async {
                          try {
                            await _postService.toggleLike(
                              postId,
                              widget.userId.toString(),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                          }
                        },
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey.shade600,
                          size: 20,
                        ),
                        label: Text(
                          '${post.likes.length}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    NavigationHelper().goToComment(
                      context,
                      postId,
                      widget.userId.toString(),
                      widget.currentUserName,
                      widget.userAvatar,
                      post.content ?? '',
                    );
                  },
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  label: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('comments')
                            .where('postId', isEqualTo: postId)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text(
                          '0',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        );
                      }
                      final commentCount = snapshot.data!.docs.length;
                      return Text(
                        '$commentCount',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String message,
    IconData icon,
    String actionText,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: Text(actionText),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
