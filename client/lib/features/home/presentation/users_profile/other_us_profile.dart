import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_app/data/repositories/Chat/User_Profile_repo/us_profile_repository.dart';
import 'package:first_app/data/repositories/Friends_repo/friends_repo.dart';
import 'package:first_app/features/home/presentation/users_profile/bloc/profile_event.dart';
import 'package:first_app/features/home/presentation/users_profile/bloc/profile_state.dart';
import 'package:first_app/features/home/presentation/users_profile/bloc/profile_bloc.dart';

class OtherProfilePage extends StatelessWidget {
  final int viewerId;
  final int targetUserId;

  const OtherProfilePage({
    Key? key,
    required this.viewerId,
    required this.targetUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              onPressed: () {
                // Implement search functionality
              },
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
                      onPressed:
                          () => context.read<OtherProfileBloc>().add(
                            LoadProfileEvent(forceRefresh: true),
                          ),
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
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // Căn giữa toàn bộ nội dung
                  children: [
                    // Profile Header
                    Stack(
                      clipBehavior:
                          Clip.none, // Cho phép nội dung vượt ra ngoài Stack
                      alignment: Alignment.topCenter,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 180,
                          child: CachedNetworkImage(
                            imageUrl: 'https://picsum.photos/800/600',
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => CircularProgressIndicator(),
                            errorWidget:
                                (context, url, error) =>
                                    Container(color: Colors.grey[200]),
                          ),
                        ),
                        Positioned(
                          top:
                              120, // Đưa ảnh đại diện lên cao hơn để chồng lên ảnh bìa
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(user.avatarUrl),
                            backgroundColor: Colors.white,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 60.0,
                      ), // Khoảng cách từ ảnh đại diện xuống tên
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            user.username,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          if (user.friendsCount != null &&
                              user.friendsCount! > 0)
                            Text(
                              '${user.friendsCount ?? 0} bạn chung',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),

                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildFriendButton(context, friendStatus),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Messaging functionality
                              },
                              icon: Icon(Icons.message),
                              label: Text('Nhắn tin'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Profile Details
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Giới thiệu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            user.bio ?? 'Chưa có thông tin giới thiệu',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                          SizedBox(height: 16),
                          if (user.location != null)
                            _buildDetailRow(
                              icon: Icons.home,
                              text: 'Sống tại ${user.location}',
                            ),
                          if (user.interests != null)
                            _buildDetailRow(
                              icon: Icons.favorite,
                              text: 'Sở thích: ${user.interests}',
                            ),
                        ],
                      ),
                    ),

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
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (user.friendsCount != null &&
                                  user.friendsCount! > 0)
                                Text(
                                  '${user.friendsCount ?? 0} bạn chung',
                                  style: TextStyle(color: Colors.blue),
                                ),
                            ],
                          ),
                          SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(
                                6,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 35,
                                        backgroundColor: Colors.grey[300],
                                      ),
                                      SizedBox(height: 4),
                                      Text('Bạn'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
          ),
        );
      case "none":
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
          ),
        );
    }
  }

  Widget _buildDetailRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          SizedBox(width: 10),
          Text(text, style: TextStyle(color: Colors.grey[800])),
        ],
      ),
    );
  }
}
