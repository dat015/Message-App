import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_app/data/repositories/Chat/User_Profile_repo/us_profile_repository.dart';
import 'package:first_app/data/repositories/Friends_repo/friends_repo.dart';
import 'package:first_app/data/repositories/Story_repo/story_repo.dart';
import 'package:first_app/data/repositories/Post_repo/post_repo.dart';
import 'package:first_app/data/models/story.dart';
import 'package:first_app/data/models/post.dart';
import 'package:first_app/features/routes/navigation_helper.dart';
import 'package:first_app/features/home/presentation/users_profile/bloc/profile_event.dart';
import 'package:first_app/features/home/presentation/users_profile/bloc/profile_state.dart';
import 'package:first_app/features/home/presentation/users_profile/bloc/profile_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart';

class OtherProfilePage extends StatelessWidget {
  final int viewerId;
  final int targetUserId;

  OtherProfilePage({
    Key? key,
    required this.viewerId,
    required this.targetUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final StoryRepository _storyRepo = StoryRepository();
    final PostRepo _postRepo = PostRepo();

    return BlocProvider(
      create:
          (context) => OtherProfileBloc(
            profileRepository: UsProfileRepository(),
            friendsRepo: FriendsRepo(),
            viewerId: viewerId,
            targetUserId: targetUserId,
          )..add(LoadProfileEvent()),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: Colors.black),
              onPressed: () {},
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: BlocBuilder<OtherProfileBloc, OtherProfileState>(
          builder: (context, state) {
            if (state is OtherProfileLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is OtherProfileError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        context.read<OtherProfileBloc>().add(
                          LoadProfileEvent(),
                        );
                      },
                      child: Text('Thử lại'),
                    ),
                  ],
                ),
              );
            } else if (state is OtherProfileLoaded) {
              final user = state.profile;
              final friendStatus = state.friendStatus;
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Header
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 200,
                          child: CachedNetworkImage(
                            imageUrl: 'https://picsum.photos/800/600',
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.blue[300],
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                          ),
                        ),
                        Positioned(
                          top: 130,
                          child: StreamBuilder<List<Story>>(
                            stream: _storyRepo.getUserStories(
                              viewerId.toString(),
                              targetUserId.toString(),
                            ),
                            builder: (context, snapshot) {
                              final bool hasStories =
                                  snapshot.hasData && snapshot.data!.isNotEmpty;
                              final bool hasUnseenStories =
                                  hasStories &&
                                  snapshot.data!.any(
                                    (story) =>
                                        !story.viewers.contains(
                                          viewerId.toString(),
                                        ),
                                  );

                              return Container(
                                padding: EdgeInsets.all(4),
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundColor: Colors.white,
                                  backgroundImage: NetworkImage(
                                    user.avatarUrl!,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 70.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            user.username,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 6),
                          if (user.friendsCount != null &&
                              user.friendsCount! > 0)
                            Text(
                              '${user.friendsCount ?? 0} bạn chung',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 20.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildFriendButton(context, friendStatus),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: Icon(Icons.message),
                              label: Text('Nhắn tin'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(thickness: 8, color: Colors.grey[100]),

                    // Profile Details
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Giới thiệu',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.bio ?? 'Chưa có thông tin giới thiệu',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 16),
                                if (user.location != null)
                                  _buildDetailRow(
                                    icon: Icons.home,
                                    text: 'Sống tại ${user.location}',
                                  ),
                                if (user.gender != null)
                                  _buildDetailRow(
                                    icon: Icons.person,
                                    text:
                                        'Giới tính: ${user.gender == 'Nam' ? 'Nam' : 'Nữ'}',
                                  ),
                                if (user.interests != null &&
                                    user.interests!.isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow(
                                        icon: Icons.favorite,
                                        text: 'Sở thích',
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
                                                      color: Colors.blue[700],
                                                      size: 18,
                                                    ),
                                                    label: Text(interest),
                                                    backgroundColor: Colors.blue
                                                        .withOpacity(0.1),
                                                    labelStyle: TextStyle(
                                                      color: Colors.blue[700],
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
                        ],
                      ),
                    ),

                    Divider(thickness: 8, color: Colors.grey[100]),

                    // Friends Section
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Bạn bè',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (user.friendsCount != null &&
                                  user.friendsCount! > 0)
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Xem tất cả',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 12),
                          state.friends.isEmpty
                              ? Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'Không có bạn bè nào để hiển thị',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                              : GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 0.8,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                itemCount:
                                    state.friends.length > 6
                                        ? 6
                                        : state.friends.length,
                                itemBuilder: (context, index) {
                                  final friend = state.friends[index];
                                  return _buildFriendItem(friend);
                                },
                              ),
                        ],
                      ),
                    ),

                    Divider(thickness: 8, color: Colors.grey[100]),

                    // Stories Section
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Khoảnh khắc',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              StreamBuilder<List<Story>>(
                                stream: _storyRepo.getUserStories(
                                  viewerId.toString(),
                                  targetUserId.toString(),
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data!.isNotEmpty) {
                                    return TextButton(
                                      onPressed: () {},
                                      child: Text(
                                        'Xem tất cả',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }
                                  return SizedBox();
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            height: 220,
                            child: StreamBuilder<List<Story>>(
                              stream: _storyRepo.getUserStories(
                                viewerId.toString(),
                                targetUserId.toString(),
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.hasError)
                                  return Center(
                                    child: Text('Lỗi: ${snapshot.error}'),
                                  );
                                if (!snapshot.hasData)
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                final stories = snapshot.data!;
                                if (stories.isEmpty) {
                                  return Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.photo_library_outlined,
                                            size: 50,
                                            color: Colors.grey[400],
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'Chưa có khoảnh khắc',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                  children:
                                      stories
                                          .map(
                                            (story) => Padding(
                                              padding: const EdgeInsets.only(
                                                right: 16,
                                              ),
                                              child: _buildStoryCard(
                                                story.authorAvatar,
                                                story.authorName,
                                                story.isImage
                                                    ? story.imageUrl!
                                                    : story.authorAvatar,
                                                isCreateNew: false,
                                                isViewed: story.viewers
                                                    .contains(
                                                      viewerId.toString(),
                                                    ),
                                                onTap:
                                                    () => NavigationHelper()
                                                        .goToStory(
                                                          context,
                                                          viewerId.toString(),
                                                          [story],
                                                        ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(thickness: 8, color: Colors.grey[100]),

                    // Posts Section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bài viết',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          StreamBuilder<List<Post>>(
                            stream: _postRepo.getUserPosts(
                              viewerId.toString(),
                              targetUserId.toString(),
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.hasError)
                                return Center(
                                  child: Text('Lỗi: ${snapshot.error}'),
                                );
                              if (!snapshot.hasData)
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              final posts = snapshot.data!;
                              if (posts.isEmpty) {
                                return Container(
                                  padding: EdgeInsets.all(30),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.post_add_outlined,
                                          size: 60,
                                          color: Colors.grey[400],
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Chưa có bài viết nào',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children:
                                    posts
                                        .map(
                                          (post) => _buildPostItem(
                                            context: context,
                                            profileImage: user.avatarUrl!,
                                            username:
                                                post.authorName ?? 'Unknown',
                                            timeAgo: _formatTimeAgo(
                                              post.createdAt,
                                            ),
                                            content: post.content ?? '',
                                            postImage:
                                                post.imageUrl ??
                                                '/images/register.png',
                                            postId: post.id!,
                                            post: post,
                                            isOwnPost:
                                                viewerId.toString() ==
                                                post.authorId,
                                          ),
                                        )
                                        .toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return Container();
          },
        ),
      ),
    );
  }

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

  Widget _buildFriendButton(BuildContext context, String friendStatus) {
    switch (friendStatus) {
      case "friend":
        return ElevatedButton.icon(
          onPressed:
              () => context.read<OtherProfileBloc>().add(UnfriendEvent()),
          icon: Icon(Icons.person),
          label: Text('Bạn bè'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.grey[200],
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        );
      case "pending":
        return ElevatedButton.icon(
          onPressed:
              () => context.read<OtherProfileBloc>().add(
                AcceptFriendRequestEvent(),
              ),
          icon: Icon(Icons.check),
          label: Text('Chấp nhận'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        );
      case "sent":
        return ElevatedButton.icon(
          onPressed:
              () => context.read<OtherProfileBloc>().add(
                CancelFriendRequestEvent(),
              ),
          icon: Icon(Icons.hourglass_empty),
          label: Text('Đã gửi lời mời'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.grey[200],
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        );
      default:
        return ElevatedButton.icon(
          onPressed:
              () => context.read<OtherProfileBloc>().add(
                SendFriendRequestEvent(),
              ),
          icon: Icon(Icons.person_add),
          label: Text('Thêm bạn'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.grey[200],
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        );
    }
  }

  Widget _buildDetailRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700], size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[800], fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(dynamic friend) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: friend.avatarUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder:
                    (context, url) => Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue[300],
                        ),
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.person, color: Colors.grey),
                    ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Text(
              friend.username,
              style: TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(
    String avatar,
    String name,
    String imagePath, {
    required bool isCreateNew,
    required bool isViewed,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Story Image Background
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: imagePath,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue[300],
                          ),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                ),
              ),

              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Content overlay (avatar and name)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isCreateNew)
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade600,
                                Colors.purple.shade600,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add, color: Colors.white, size: 20),
                        )
                      else
                        Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isViewed ? Colors.grey : Colors.blue,
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(avatar),
                          ),
                        ),
                      SizedBox(height: 8),
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // "Unseen" indicator at top
              if (!isViewed && !isCreateNew)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostItem({
    required BuildContext context,
    required String profileImage,
    required String username,
    required String content,
    required String timeAgo,
    required String postImage,
    required String postId,
    required Post post,
    required bool isOwnPost,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                StreamBuilder<List<Story>>(
                  stream: FirebaseFirestore.instance
                      .collection('stories')
                      .where('authorId', isEqualTo: post.authorId)
                      .snapshots()
                      .map((snapshot) {
                        return snapshot.docs
                            .map((doc) => Story.fromMap(doc.id, doc.data()))
                            .toList();
                      }),
                  builder: (context, snapshot) {
                    final bool hasStories =
                        snapshot.hasData && snapshot.data!.isNotEmpty;
                    final bool hasUnseenStories =
                        hasStories &&
                        snapshot.data!.any(
                          (story) =>
                              !story.viewers.contains(viewerId.toString()),
                        );

                    return Container(
                      padding: EdgeInsets.all(2),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(profileImage),
                      ),
                    );
                  },
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwnPost)
                  IconButton(
                    icon: Icon(Icons.more_horiz, color: Colors.grey.shade700),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context as BuildContext,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder:
                            (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  margin: EdgeInsets.symmetric(vertical: 8),
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                ListTile(
                                  leading: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.edit, color: Colors.blue),
                                  ),
                                  title: Text('Chỉnh sửa bài viết'),
                                  onTap: () {
                                    NavigationHelper().pop(context);
                                    NavigationHelper().goToEditPost(
                                      context,
                                      post,
                                      viewerId.toString(),
                                      username,
                                      profileImage,
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                    'Xóa bài viết',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onTap: () {
                                    NavigationHelper().pop(context);
                                    _deletePost(context, postId);
                                  },
                                ),
                                SizedBox(height: 20),
                              ],
                            ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // Post Content
          if (content.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(content, style: TextStyle(fontSize: 16, height: 1.4)),
            ),

          // Post Image
          if (postImage != '/images/register.png')
            Container(
              margin: EdgeInsets.only(top: 12),
              constraints: BoxConstraints(maxHeight: 400),
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: postImage,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.blue[300],
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                      ),
                    ),
              ),
            ),

          // Post Actions
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Likes and Comments Count
                Row(
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('posts')
                              .doc(postId)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists)
                          return SizedBox();

                        final postData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final post = Post.fromMap(postId, postData);

                        if (post.likes.isNotEmpty) {
                          return Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.thumb_up,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                '${post.likes.length}',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          );
                        }
                        return SizedBox();
                      },
                    ),
                    Spacer(),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('comments')
                              .where('postId', isEqualTo: postId)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return SizedBox();

                        final commentCount = snapshot.data!.docs.length;
                        if (commentCount > 0) {
                          return Text(
                            '$commentCount bình luận',
                            style: TextStyle(color: Colors.grey.shade700),
                          );
                        }
                        return SizedBox();
                      },
                    ),
                  ],
                ),

                SizedBox(height: 12),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                SizedBox(height: 4),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<DocumentSnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('posts')
                                .doc(postId)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || !snapshot.data!.exists)
                            return SizedBox();

                          final postData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final post = Post.fromMap(postId, postData);
                          final isLiked = post.likes.contains(
                            viewerId.toString(),
                          );

                          return TextButton.icon(
                            onPressed: () async {
                              try {
                                await PostRepo().toggleLike(
                                  postId,
                                  viewerId.toString(),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: $e'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color:
                                  isLiked ? Colors.red : Colors.grey.shade600,
                              size: 20,
                            ),
                            label: Text(
                              'Thích',
                              style: TextStyle(
                                color:
                                    isLiked ? Colors.red : Colors.grey.shade700,
                                fontWeight:
                                    isLiked
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              foregroundColor: Colors.grey.shade600,
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final profileRepo = UsProfileRepository();
                          final currentUser = await profileRepo.fetchUserProfile(viewerId);
                          NavigationHelper().goToComment(
                            context as BuildContext,
                            postId,
                            viewerId.toString(),
                            currentUser.username,
                            currentUser.avatarUrl ?? '',
                            post.content ?? '',
                          );
                        },
                        icon: Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        label: Text(
                          'Bình luận',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {},
                        icon: Icon(
                          Icons.share_outlined,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        label: Text(
                          'Chia sẻ',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(BuildContext context, String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Xóa bài viết'),
            content: Text('Bạn có chắc muốn xóa bài viết này?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await PostRepo().deletePost(postId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xóa bài viết thành công'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Đóng',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Đóng',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 365)
      return '${(difference.inDays / 365).floor()} năm trước';
    if (difference.inDays > 30)
      return '${(difference.inDays / 30).floor()} tháng trước';
    if (difference.inDays > 0) return '${difference.inDays} ngày trước';
    if (difference.inHours > 0) return '${difference.inHours} giờ trước';
    if (difference.inMinutes > 0) return '${difference.inMinutes} phút trước';
    return 'Vừa xong';
  }
}
