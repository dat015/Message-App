import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/dto/friendrequest_withdetails.dart';
import 'package:first_app/data/models/friendsuggestion.dart';
import 'package:first_app/data/models/user.dart';
import 'package:first_app/data/repositories/Friends_repo/friends_repo.dart';
import 'package:first_app/features/search/presentation/screens/searchUsers.dart';
import 'package:flutter/material.dart';

class Friends extends StatefulWidget {
  final int currentUserId;

  const Friends({
    super.key,
    required this.currentUserId,
  });

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<Friends> with SingleTickerProviderStateMixin {
  List<FriendRequestWithDetails> friendRequests = [];
  List<FriendRequestWithDetails> sentFriendRequests = [];
  List<FriendSuggestion> friendSuggestions = [];
  List<User> friends = [];
  bool isLoadingRequests = true;
  bool isLoadingSentRequests = true;
  bool isLoadingSuggestions = true;
  bool isLoadingFriends = true;
  late FriendsRepo _friendsRepo;
  late TabController _tabController;
  final ApiClient _apiService = ApiClient();

  @override
  void initState() {
    super.initState();
    _friendsRepo = FriendsRepo();
    _tabController = TabController(length: 3, vsync: this);
    _loadFriendRequests();
    _loadSentFriendRequests();
    _loadFriendSuggestions();
    _loadFriends();
  }

  // Keep your existing data loading methods (_loadFriendRequests, _loadSentFriendRequests, etc.)
  Future<void> _loadFriendRequests() async {
    setState(() => isLoadingRequests = true);
    try {
      final requests = await _friendsRepo.getFriendRequests(widget.currentUserId);
      setState(() {
        friendRequests = requests;
        isLoadingRequests = false;
      });
    } catch (e) {
      setState(() => isLoadingRequests = false);
      _showErrorSnackBar('Failed to load friend requests: $e');
    }
  }

  Future<void> _loadSentFriendRequests() async {
    setState(() => isLoadingSentRequests = true);
    try {
      final requests = await _friendsRepo.getSentFriendRequests(widget.currentUserId);
      setState(() {
        sentFriendRequests = requests;
        isLoadingSentRequests = false;
      });
    } catch (e) {
      setState(() => isLoadingSentRequests = false);
      _showErrorSnackBar('Failed to load sent friend requests: $e');
    }
  }

  Future<void> _loadFriendSuggestions() async {
    setState(() => isLoadingSuggestions = true);
    try {
      final suggestions = await _friendsRepo.getFriendSuggestions(widget.currentUserId);
      setState(() {
        friendSuggestions = suggestions;
        isLoadingSuggestions = false;
      });
    } catch (e) {
      setState(() => isLoadingSuggestions = false);
      _showErrorSnackBar('Failed to load friend suggestions: $e');
    }
  }

  Future<void> _loadFriends() async {
    setState(() => isLoadingFriends = true);
    try {
      final friendList = await _friendsRepo.getFriends(widget.currentUserId);
      setState(() {
        friends = friendList;
        isLoadingFriends = false;
      });
    } catch (e) {
      setState(() => isLoadingFriends = false);
      _showErrorSnackBar('Failed to load friends: $e');
    }
  }

  // Keep your existing action methods (_searchUsers, _acceptFriendRequest, etc.)
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên người dùng để tìm kiếm')),
      );
      return;
    }
    try {
      final response = await _apiService.get('api/friends/search?username=$query&senderId=${widget.currentUserId}');
      final List<dynamic> users = response as List<dynamic>;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchUsersScreen(
            searchResults: users,
            currentUserId: widget.currentUserId,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Lỗi khi tìm kiếm người dùng: $e');
    }
  }

  Future<void> _acceptFriendRequest(BuildContext context, int requestId, String username, int index) async {
    setState(() => isLoadingRequests = true);
    try {
      await _friendsRepo.acceptFriendRequest(requestId);
      setState(() {
        friendRequests.removeAt(index);
        isLoadingRequests = false;
      });
      await _loadFriends();
      _showSuccessSnackBar('Đã chấp nhận lời mời từ $username');
    } catch (e) {
      setState(() => isLoadingRequests = false);
      _showErrorSnackBar('Lỗi khi chấp nhận: $e');
    }
  }

  Future<void> _rejectFriendRequest(BuildContext context, int requestId, String username, int index) async {
    setState(() => isLoadingRequests = true);
    try {
      await _friendsRepo.rejectFriendRequest(requestId);
      setState(() {
        friendRequests.removeAt(index);
        isLoadingRequests = false;
      });
      _showSuccessSnackBar('Đã từ chối lời mời từ $username');
    } catch (e) {
      setState(() => isLoadingRequests = false);
      _showErrorSnackBar('Lỗi khi từ chối: $e');
    }
  }

  Future<void> _sendFriendRequest(BuildContext context, int receiverId, String username, String avatarUrl, int index) async {
    try {
      await _friendsRepo.sendFriendRequest(widget.currentUserId, receiverId, username, avatarUrl);
      setState(() {
        friendSuggestions.removeAt(index);
      });
      await _loadSentFriendRequests();
      _showSuccessSnackBar('Đã gửi lời mời kết bạn đến $username');
    } catch (e) {
      _showErrorSnackBar('Lỗi khi gửi lời mời: $e');
    }
  }

  Future<void> _cancelFriendRequest(BuildContext context, int requestId, int senderId, int receiverId, String username, int index) async {  // Removed unused parameters
  try {
    await _friendsRepo.cancelFriendRequest(senderId, receiverId);
    setState(() {
      sentFriendRequests.removeAt(index);
    });
    _showSuccessSnackBar('Đã hủy lời mời gửi đến $username');
  } catch (e) {
    _showErrorSnackBar('Lỗi khi hủy lời mời: $e');
  }
}

  Future<void> _unfriend(BuildContext context, int friendId, String username, int index) async {
    try {
      await _friendsRepo.unfriend(widget.currentUserId, friendId);
      setState(() {
        friends.removeAt(index);
      });
      _showSuccessSnackBar('Đã xóa $username khỏi danh sách bạn bè');
    } catch (e) {
      _showErrorSnackBar('Lỗi khi xóa bạn bè: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
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

  Widget _buildFriendRequestItem(FriendRequestWithDetails item, int index, double screenWidth) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(item.friend.avatarUrl),
              onBackgroundImageError: (_, __) => const Icon(Icons.person, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.friend.username,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      TextButton(
                        onPressed: () => _acceptFriendRequest(context, item.request.id, item.friend.username, index),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Chấp nhận'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => _rejectFriendRequest(context, item.request.id, item.friend.username, index),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[800],
                          backgroundColor: Colors.grey[200],
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Từ chối'),
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

  Widget _buildSentFriendRequestItem(FriendRequestWithDetails item, int index, double screenWidth) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(item.friend.avatarUrl),
              onBackgroundImageError: (_, __) => const Icon(Icons.person, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.friend.username,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatRequestTime(item.request.createdAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đang chờ xác nhận',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () => _cancelFriendRequest(context, item.request.id, item.request.senderId, item.request.receiverId, item.friend.username, index),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[800],
                          backgroundColor: Colors.grey[200],
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Hủy'),
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

  Widget _buildFriendSuggestionItem(FriendSuggestion suggestion, int index, double screenWidth) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(suggestion.avatarUrl),
              onBackgroundImageError: (_, __) => const Icon(Icons.person, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.username,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (suggestion.mutualFriendsCount > 0)
                    Text(
                      '${suggestion.mutualFriendsCount} bạn chung',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  if (suggestion.sameLocation)
                    const Text(
                      'Cùng khu vực',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _sendFriendRequest(context, suggestion.userId, suggestion.username, suggestion.avatarUrl, index),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Thêm bạn'),
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

  Widget _buildFriendItem(User friend, int index, double screenWidth) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(friend.avatarUrl),
              onBackgroundImageError: (_, __) => const Icon(Icons.person, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.username,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _unfriend(context, friend.id, friend.username, index),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Xóa bạn'),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bạn bè',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              showSearch(context: context, delegate: CustomSearchDelegate(onSearch: _searchUsers));
            },
          ),
        ],
        bottom: TabBar(
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
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Suggestions Tab
          Container(
            color: Colors.grey[100],
            height: screenHeight,
            child: isLoadingSuggestions
                ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                : friendSuggestions.isEmpty
                    ? _buildEmptyState('Không có gợi ý kết bạn')
                    : ListView.builder(
                        itemCount: friendSuggestions.length,
                        itemBuilder: (context, index) =>
                            _buildFriendSuggestionItem(friendSuggestions[index], index, screenHeight),
                      ),
          ),
          // Friend Requests Tab
          Container(
            color: Colors.grey[100],
            height: screenHeight,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sent Requests
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Lời mời đã gửi (${sentFriendRequests.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  isLoadingSentRequests
                      ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                      : sentFriendRequests.isEmpty
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
                              itemCount: sentFriendRequests.length,
                              itemBuilder: (context, index) => _buildSentFriendRequestItem(
                                  sentFriendRequests[index], index, screenHeight),
                            ),
                  const Divider(height: 1),
                  // Received Requests
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Lời mời đã nhận (${friendRequests.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  isLoadingRequests
                      ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                      : friendRequests.isEmpty
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
                              itemCount: friendRequests.length,
                              itemBuilder: (context, index) =>
                                  _buildFriendRequestItem(friendRequests[index], index, screenHeight),
                            ),
                ],
              ),
            ),
          ),
          // Friends Tab
          Container(
            color: Colors.grey[100],
            height: screenHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Bạn bè (${friends.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: isLoadingFriends
                      ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                      : friends.isEmpty
                          ? _buildEmptyState('Bạn chưa có bạn bè nào')
                          : ListView.builder(
                              itemCount: friends.length,
                              itemBuilder: (context, index) => _buildFriendItem(friends[index], index, screenHeight),
                            ),
                ),
              ],
            ),
          ),
        ],
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
}

class CustomSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearch;

  CustomSearchDelegate({required this.onSearch});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) {
      onSearch(query);
    }
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}