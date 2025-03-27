import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/dto/friendrequest_withdetails.dart';
import 'package:first_app/data/models/friendsuggestion.dart';
import 'package:first_app/data/models/user.dart';
import 'package:first_app/features/home/presentation/users_profile/other_us_profile.dart';
import 'package:first_app/data/repositories/Friends_repo/friends_repo.dart';
import 'package:first_app/features/search/presentation/screens/searchUsers.dart';
import 'package:flutter/material.dart';

class Friends extends StatefulWidget {
  final int currentUserId;

  const Friends({super.key, required this.currentUserId});

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<Friends>
    with SingleTickerProviderStateMixin {
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

  void _navigateToProfile(int targetUserId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OtherProfilePage(
              viewerId: widget.currentUserId,
              targetUserId: targetUserId,
            ),
      ),
    );
  }

  Future<void> _loadFriendRequests() async {
    setState(() => isLoadingRequests = true);
    try {
      final requests = await _friendsRepo.getFriendRequests(
        widget.currentUserId,
      );
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
      final requests = await _friendsRepo.getSentFriendRequests(
        widget.currentUserId,
      );
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
      final suggestions = await _friendsRepo.getFriendSuggestions(
        widget.currentUserId,
      );
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

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên người dùng để tìm kiếm'),
        ),
      );
      return;
    }
    try {
      final response = await _apiService.get(
        'api/friends/search?username=$query&senderId=${widget.currentUserId}',
      );
      final List<dynamic> users = response as List<dynamic>;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SearchUsersScreen(
                searchResults: users,
                currentUserId: widget.currentUserId,
              ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Lỗi khi tìm kiếm người dùng: $e');
    }
  }

  Future<void> _acceptFriendRequest(
    BuildContext context,
    int requestId,
    String username,
    int index,
  ) async {
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

  Future<void> _rejectFriendRequest(
    BuildContext context,
    int requestId,
    String username,
    int index,
  ) async {
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

  Future<void> _sendFriendRequest(
    BuildContext context,
    int receiverId,
    String username,
    String avatarUrl,
    int index,
  ) async {
    try {
      await _friendsRepo.sendFriendRequest(
        widget.currentUserId,
        receiverId,
        username,
        avatarUrl,
      );
      setState(() {
        friendSuggestions.removeAt(index);
      });
      await _loadSentFriendRequests();
      _showSuccessSnackBar('Đã gửi lời mời kết bạn đến $username');
    } catch (e) {
      _showErrorSnackBar('Lỗi khi gửi lời mời: $e');
    }
  }

  Future<void> _cancelFriendRequest(
    BuildContext context,
    int requestId,
    int senderId,
    int receiverId,
    String username,
    int index,
  ) async {
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

  Future<void> _unfriend(
    BuildContext context,
    int friendId,
    String username,
    int index,
  ) async {
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
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 6,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 6,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  ElevatedButton _buildStyledButton({
    required VoidCallback onPressed,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    Color? textColor,
    double elevation = 2,
    EdgeInsets padding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: elevation,
      ),
      child: Text(label, style: TextStyle(color: textColor ?? Colors.white)),
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

  Widget _buildFriendRequestItem(
    FriendRequestWithDetails item,
    int index,
    double screenWidth,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _navigateToProfile(item.friend.senderId),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(item.friend.avatarUrl),
                onBackgroundImageError:
                    (_, __) => const Icon(Icons.person, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToProfile(item.friend.senderId),
                        child: Text(
                          item.friend.username,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        _formatRequestTime(item.request.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
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
                      _buildStyledButton(
                        onPressed:
                            () => _acceptFriendRequest(
                              context,
                              item.request.id,
                              item.friend.username,
                              index,
                            ),
                        label: 'Chấp nhận',
                        backgroundColor: Colors.blue[600]!,
                        foregroundColor: Colors.blue[800]!,
                      ),
                      const SizedBox(width: 8),
                      _buildStyledButton(
                        onPressed:
                            () => _rejectFriendRequest(
                              context,
                              item.request.id,
                              item.friend.username,
                              index,
                            ),
                        label: 'Từ chối',
                        backgroundColor: Colors.grey[300]!,
                        foregroundColor: Colors.grey[500]!,
                        textColor: Colors.grey[800],
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

  Widget _buildSentFriendRequestItem(
    FriendRequestWithDetails item,
    int index,
    double screenWidth,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _navigateToProfile(item.friend.receiverId),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(item.friend.avatarUrl),
                onBackgroundImageError:
                    (_, __) => const Icon(Icons.person, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToProfile(item.friend.receiverId),
                        child: Text(
                          item.friend.username,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        _formatRequestTime(item.request.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (item.friend.mutualFriendsCount > 0)
                    Text(
                      '${item.friend.mutualFriendsCount} bạn chung',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đang chờ xác nhận',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      _buildStyledButton(
                        onPressed:
                            () => _cancelFriendRequest(
                              context,
                              item.request.id,
                              item.request.senderId,
                              item.request.receiverId,
                              item.friend.username,
                              index,
                            ),
                        label: 'Hủy',
                        backgroundColor: Colors.grey[300]!,
                        foregroundColor: Colors.grey[500]!,
                        textColor: Colors.grey[800],
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

  Widget _buildFriendSuggestionItem(
    FriendSuggestion suggestion,
    int index,
    double screenWidth,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _navigateToProfile(suggestion.userId),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(suggestion.avatarUrl),
                onBackgroundImageError:
                    (_, __) => const Icon(Icons.person, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _navigateToProfile(suggestion.userId),
                    child: Text(
                      suggestion.username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (suggestion.mutualFriendsCount > 0)
                    Text(
                      '${suggestion.mutualFriendsCount} bạn chung',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildStyledButton(
                      onPressed:
                          () => _sendFriendRequest(
                            context,
                            suggestion.userId,
                            suggestion.username,
                            suggestion.avatarUrl,
                            index,
                          ),
                      label: 'Thêm bạn',
                      backgroundColor: Colors.blue[600]!,
                      foregroundColor: Colors.blue[800]!,
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
            GestureDetector(
              onTap: () => _navigateToProfile(friend.id),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(friend.avatarUrl),
                onBackgroundImageError:
                    (_, __) => const Icon(Icons.person, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _navigateToProfile(friend.id),
                    child: Text(
                      friend.username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (friend.mutualFriendsCount > 0)
                    Text(
                      '${friend.mutualFriendsCount} bạn chung',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildStyledButton(
                      onPressed:
                          () => _unfriend(
                            context,
                            friend.id,
                            friend.username,
                            index,
                          ),
                      label: 'Hủy kết bạn',
                      backgroundColor: Colors.red[600]!,
                      foregroundColor: Colors.red[800]!,
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
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(onSearch: _searchUsers),
              );
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
          Container(
            color: Colors.grey[100],
            height: screenHeight,
            child:
                isLoadingSuggestions
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    )
                    : friendSuggestions.isEmpty
                    ? _buildEmptyState('Không có gợi ý kết bạn')
                    : ListView.builder(
                      itemCount: friendSuggestions.length,
                      itemBuilder:
                          (context, index) => _buildFriendSuggestionItem(
                            friendSuggestions[index],
                            index,
                            screenHeight,
                          ),
                    ),
          ),
          Container(
            color: Colors.grey[100],
            height: screenHeight,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Lời mời đã gửi (${sentFriendRequests.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  isLoadingSentRequests
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.blue),
                      )
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
                        itemBuilder:
                            (context, index) => _buildSentFriendRequestItem(
                              sentFriendRequests[index],
                              index,
                              screenHeight,
                            ),
                      ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Lời mời đã nhận (${friendRequests.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  isLoadingRequests
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.blue),
                      )
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
                        itemBuilder:
                            (context, index) => _buildFriendRequestItem(
                              friendRequests[index],
                              index,
                              screenHeight,
                            ),
                      ),
                ],
              ),
            ),
          ),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child:
                      isLoadingFriends
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.blue,
                            ),
                          )
                          : friends.isEmpty
                          ? _buildEmptyState('Bạn chưa có bạn bè nào')
                          : ListView.builder(
                            itemCount: friends.length,
                            itemBuilder:
                                (context, index) => _buildFriendItem(
                                  friends[index],
                                  index,
                                  screenHeight,
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
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
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
