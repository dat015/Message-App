import 'package:first_app/data/dto/friend_dto.dart';
import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/models/conversation.dart';
import 'package:first_app/data/repositories/Conversations_repo/conversations_repository.dart';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';
import 'package:first_app/data/repositories/Friends_repo/friends_repo.dart';
import 'package:first_app/data/repositories/GroupSettting/group_settting_repo.dart';
import 'package:first_app/data/dto/group_setting_dto.dart';
import 'package:first_app/features/home/presentation/screens/home_screen/GroupPermissionSetupScreen.dart';
import 'package:flutter/material.dart';

class CreateGroupScreen extends StatefulWidget {
  final int userId;
  final List<FriendDTO> friends;
  final ConversationRepo conversationRepo;
  final List<FriendDTO>? selectedFriends;

  const CreateGroupScreen({
    Key? key,
    required this.userId,
    required this.friends,
    required this.conversationRepo,
    this.selectedFriends,
  }) : super(key: key);

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<int> _selectedFriendIds = [];
  List<FriendDTO> _filteredFriends = [];
  WebSocketService webSocketService = WebSocketService();
  FriendsRepo friendRepo = FriendsRepo();
  GroupSettingRepo _groupSettingRepo = GroupSettingRepo();
  List<FriendDTO> _allFriends = [];
  GroupSettingDTO? _groupSettings;

  @override
  void initState() {
    super.initState();
    // Log dữ liệu gốc của widget.friends
    print('Initial friends count: ${widget.friends.length}');
    print(
      'Friends data: ${widget.friends.map((f) => 'friendId: ${f.friendId}, username: ${f.username}').toList()}',
    );

    // Không loại bỏ trùng lặp friendId, giữ nguyên danh sách bạn bè
    _filteredFriends = List.from(widget.friends);
    // Kiểm tra friendId null và cảnh báo
    for (var friend in _filteredFriends) {
      if (friend.friendId == null) {
        print(
          'Warning: Friend with username ${friend.username} has null friendId',
        );
      }
    }
    _filteredFriends.sort(
      (a, b) => (a.username ?? '').compareTo(b.username ?? ''),
    );

    // Không khởi tạo _selectedFriendIds từ widget.selectedFriends
    print('Initial selected friends: $_selectedFriendIds');

    // Thêm listener cho _groupNameController để cập nhật giao diện khi tên nhóm thay đổi
    _groupNameController.addListener(() {
      setState(() {
        // Cập nhật giao diện để kiểm tra điều kiện enable/disable nút
        print('Group name updated: ${_groupNameController.text}');
      });
    });

    _searchController.addListener(_filterFriends);
  }

  void _filterFriends() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFriends =
          _allFriends.where((friend) {
              final username = friend.username?.toLowerCase() ?? '';
              return username.contains(query);
            }).toList()
            ..sort((a, b) => (a.username ?? '').compareTo(b.username ?? ''));
    });
  }

  Future<void> _fetchFriends() async {
    var userId = widget.userId;
    try {
      final friends = await friendRepo.getFriendsDTO(userId);
      setState(() {
        _allFriends = friends;
        _filteredFriends = friends;
      });
    } catch (e) {
      print("Lỗi khi lấy danh sách bạn bè: $e");
    }
  }

  Future<void> _showPermissionSetup() async {
    final settings = await Navigator.push<GroupSettingDTO>(
      context,
      MaterialPageRoute(
        builder:
            (context) => GroupPermissionSetupScreen(
              userId: widget.userId,
              onPermissionsSet: (settings) {
                Navigator.pop(
                  context,
                  settings,
                ); // Đảm bảo quay lại với settings
              },
            ),
      ),
    );

    if (settings != null) {
      setState(() {
        _groupSettings = settings;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu cài đặt quyền'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _createGroup() async {
    if (_groupNameController.text.isEmpty || _selectedFriendIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng nhập tên nhóm và chọn ít nhất một thành viên',
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final conversation = await widget.conversationRepo.createGroup(
        widget.userId,
        _groupNameController.text,
        _selectedFriendIds,
      );

      if (conversation != null) {
        try {
          // Create group settings if not set
          if (_groupSettings == null) {
            _groupSettings = GroupSettingDTO(
              conversationId: conversation.id!,
              allowMemberInvite: false,
              allowMemberEdit: false,
              allowMemberRemove: false,
              createdBy: widget.userId,
            );
          } else {
            _groupSettings = GroupSettingDTO(
              conversationId: conversation.id!,
              allowMemberInvite: _groupSettings!.allowMemberInvite,
              allowMemberEdit: _groupSettings!.allowMemberEdit,
              allowMemberRemove: _groupSettings!.allowMemberRemove,
              createdBy: widget.userId,
            );
          }

          // Create group settings
          var result = await _groupSettingRepo.createGroupSetting(
            conversation.id!,
            widget.userId,
            _groupSettings!.allowMemberInvite,
            _groupSettings!.allowMemberEdit,
            _groupSettings!.allowMemberRemove,
          );

          // Close loading indicator
          Navigator.pop(context);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo nhóm thành công'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Return to previous screen
          Navigator.pop(context);
        } catch (e) {
          // Close loading indicator
          Navigator.pop(context);

          // Show error message for group settings
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi cài đặt quyền nhóm: ${e.toString()}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );

          // Still return to previous screen since group was created
          Navigator.pop(context);
        }
      } else {
        // Close loading indicator
        Navigator.pop(context);

        throw Exception('Không thể tạo nhóm');
      }
    } catch (e) {
      // Close loading indicator if it's showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('500')
                ? 'Lỗi server: Vui lòng thử lại sau'
                : 'Lỗi khi tạo nhóm: ${e.toString()}',
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tạo nhóm mới',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh nhập tên nhóm
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: 'Tên nhóm',
                hintText: 'Nhập tên nhóm của bạn',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16.0),

            // Permission Setup Button
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.security,
                  color: _groupSettings != null ? Colors.green : Colors.blue,
                ),
                title: Text(
                  _groupSettings != null
                      ? 'Đã cài đặt quyền'
                      : 'Cài đặt quyền nhóm',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _groupSettings != null ? Colors.green : Colors.blue,
                  ),
                ),
                subtitle: Text(
                  _groupSettings != null
                      ? 'Nhấn để thay đổi cài đặt quyền'
                      : 'Nhấn để cài đặt quyền cho nhóm',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showPermissionSetup,
              ),
            ),
            const SizedBox(height: 16.0),

            // Tiêu đề danh sách
            Text(
              'Chọn thành viên (${_selectedFriendIds.length} đã chọn)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8.0),
            // Danh sách bạn bè
            Expanded(
              child:
                  widget.friends.isEmpty
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Bạn chưa có bạn bè nào',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                      : _filteredFriends.isEmpty
                      ? const Center(
                        child: Text(
                          'Không tìm thấy bạn bè',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _filteredFriends.length,
                        itemBuilder: (context, index) {
                          final friend = _filteredFriends[index];
                          return TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: Duration(
                              milliseconds: 300 + (index * 100),
                            ),
                            builder: (context, opacity, child) {
                              return Opacity(
                                opacity: opacity,
                                child: Transform.translate(
                                  offset: Offset(20 - opacity * 20, 0),
                                  child: child,
                                ),
                              );
                            },
                            child: Card(
                              key: ValueKey(friend.friendId ?? index),
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: CheckboxListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                                secondary: CircleAvatar(
                                  radius: 22,
                                  backgroundImage: NetworkImage(
                                    friend.avatar ??
                                        'https://via.placeholder.com/150',
                                  ),
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.transparent,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  friend.username ?? 'Không xác định',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    fontFamily: 'Roboto',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                value:
                                    friend.friendId != null &&
                                    _selectedFriendIds.contains(
                                      friend.friendId,
                                    ),
                                onChanged: (selected) {
                                  if (friend.friendId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Lỗi: Bạn bè không có friendId hợp lệ',
                                        ),
                                        backgroundColor: Colors.redAccent,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    if (selected == true &&
                                        !_selectedFriendIds.contains(
                                          friend.friendId,
                                        )) {
                                      _selectedFriendIds.add(friend.friendId!);
                                      print(
                                        'Added friendId: ${friend.friendId}, Selected: $_selectedFriendIds',
                                      );
                                    } else if (selected == false) {
                                      _selectedFriendIds.remove(
                                        friend.friendId,
                                      );
                                      print(
                                        'Removed friendId: ${friend.friendId}, Selected: $_selectedFriendIds',
                                      );
                                    }
                                  });
                                },
                                activeColor: Colors.blue,
                                checkColor: Colors.white,
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 16.0),
            // Nút tạo nhóm
            SizedBox(
              width: double.infinity,
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 1.0, end: 1.0),
                duration: const Duration(milliseconds: 100),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: ElevatedButton(
                      onPressed:
                          (_groupNameController.text.trim().isEmpty ||
                                  _selectedFriendIds.isEmpty)
                              ? null
                              : _createGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        disabledBackgroundColor: Colors.grey[400],
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                      child: Text(
                        'Tạo nhóm (${_selectedFriendIds.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
