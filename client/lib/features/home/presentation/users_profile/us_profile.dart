import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/models/user_profile.dart';
import 'package:first_app/data/repositories/Chat/User_Profile_repo/us_profile_repository.dart';
import 'package:flutter/material.dart';
void main() {
  runApp(FacebookProfileApp());
}

class FacebookProfileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trang Cá Nhân',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ProfilePage(userId: 1), // Thay 1 bằng userId thực tế
    );
  }
}

class ProfilePage extends StatefulWidget {
  final int userId;

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserProfile> userProfileFuture;
  final UsProfileRepository _usProfileRepository = UsProfileRepository();

  @override
  void initState() {
    super.initState();
    userProfileFuture = _usProfileRepository.fetchUserProfile(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<UserProfile>(
        future: userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final user = snapshot.data!;
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // CachedNetworkImage(
                        //   imageUrl: 'https://picsum.photos/800/600',
                        //   fit: BoxFit.cover,
                        // ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.username,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user.bio ?? 'Chưa có thông tin',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileStatistics(friendsCount: user.friendsCount),
                        SizedBox(height: 16),
                        ProfileActions(),
                        SizedBox(height: 16),
                        AboutSection(
                          interests: user.interests,
                          location: user.location,
                          bio: user.bio,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return PostCard(post: posts[index]); // Giữ nguyên posts tĩnh hoặc tích hợp API sau
                    },
                    childCount: posts.length,
                  ),
                ),
              ],
            );
          }
          return Container();
        },
      ),
    );
  }

  final List<Post> posts = [
    Post(
      username: 'Nguyễn Văn A',
      avatarUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
      imageUrl: 'https://picsum.photos/600/400',
      caption: 'Chuyến du lịch tuyệt vời!',
      likes: 128,
      comments: 24,
    ),
    Post(
      username: 'Nguyễn Văn A',
      avatarUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
      imageUrl: 'https://picsum.photos/600/401',
      caption: 'Khoảnh khắc đáng nhớ',
      likes: 256,
      comments: 45,
    ),
  ];
}

class ProfileStatistics extends StatelessWidget {
  final int? friendsCount;

  ProfileStatistics({required this.friendsCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatColumn('Bạn bè', (friendsCount ?? 0).toString()),
        _buildStatColumn('Người theo dõi', '5,678'),
        _buildStatColumn('Đang theo dõi', '456'),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class ProfileActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.add),
            label: Text('Thêm tin'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.blue,
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.edit),
            label: Text('Chỉnh sửa'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}

class AboutSection extends StatelessWidget {
  final String? interests;
  final String? location;
  final String? bio;

  AboutSection({this.interests, this.location, this.bio});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giới thiệu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Text(
          bio ?? 'Chưa có thông tin giới thiệu',
          style: TextStyle(color: Colors.grey[800]),
        ),
        SizedBox(height: 10),
        if (interests != null)
          _buildInfoRow(Icons.favorite, 'Sở thích: $interests'),
        if (location != null)
          _buildInfoRow(Icons.location_on, 'Sống tại $location'),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(post.avatarUrl),
            ),
            title: Text(post.username),
            subtitle: Text('Hôm nay'),
            trailing: IconButton(
              icon: Icon(Icons.more_horiz),
              onPressed: () {},
            ),
          ),
          // if (post.imageUrl.isNotEmpty)
          //   CachedNetworkImage(
          //     imageUrl: post.imageUrl,
          //     width: double.infinity,
          //     height: 250,
          //     fit: BoxFit.cover,
          //   ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              post.caption,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInteractionButton(Icons.thumb_up_alt_outlined, 'Thích', post.likes),
                _buildInteractionButton(Icons.comment_outlined, 'Bình luận', post.comments),
                _buildInteractionButton(Icons.share_outlined, 'Chia sẻ', 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton(IconData icon, String label, int count) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey),
        SizedBox(width: 5),
        Text(
          count > 0 ? '$label ($count)' : label,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

class Post {
  final String username;
  final String avatarUrl;
  final String imageUrl;
  final String caption;
  final int likes;
  final int comments;

  Post({
    required this.username,
    required this.avatarUrl,
    required this.imageUrl,
    required this.caption,
    required this.likes,
    required this.comments,
  });
}