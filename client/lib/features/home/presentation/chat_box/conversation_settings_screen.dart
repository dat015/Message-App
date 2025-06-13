import 'dart:io';

import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/providers/providers.dart';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';
import 'package:first_app/data/repositories/Message_Repo/message_repository.dart';
import 'package:first_app/data/repositories/User_Repo/user_repo.dart';
import 'package:first_app/features/home/presentation/chat_box/chat.dart';
import 'package:first_app/features/home/presentation/chat_box/members_screen.dart';
import 'package:first_app/features/home/presentation/chat_box/search_messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:first_app/data/models/conversation.dart';
import 'package:first_app/data/models/participants.dart';
import 'package:first_app/data/repositories/Conversations_repo/conversations_repository.dart';
import 'package:first_app/data/repositories/Participants_Repo/participants_repo.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:first_app/data/repositories/GroupSettting/group_settting_repo.dart';
import 'package:first_app/data/dto/group_setting_dto.dart';

class ConversationSettingsScreen extends StatefulWidget {
  final Conversation conversation;
  final int currentUserId;
  final List<MessageWithAttachment> messages;
  final Function(int) onConversationRemoved; // Callback để xóa conversation
  final Function(MessageWithAttachment)? updateChatListCallback;

  const ConversationSettingsScreen({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.messages,
    required this.onConversationRemoved,
    required this.updateChatListCallback,
  });

  @override
  State<ConversationSettingsScreen> createState() =>
      _ConversationSettingsScreenState();
}

class _ConversationSettingsScreenState extends State<ConversationSettingsScreen>
    with TickerProviderStateMixin {
  final ConversationRepo _conversationRepo = ConversationRepo();
  final ParticipantsRepo _participantsRepo = ParticipantsRepo();
  final GroupSettingRepo _groupSettingRepo = GroupSettingRepo();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _imageUrlController =
      TextEditingController(); //controller cho URL ảnh
  final MessageRepo _messageRepo = MessageRepo();
  final UserRepo _userRepo = UserRepo();
  late ChatScreen _chatScreen;
  List<Participants> _participants = [];
  XFile? _pickedImage;
  String? _groupImageUrl; // Biến để lưu URL ảnh tạm thời
  bool _isUploading = false; // Biến để theo dõi trạng thái tải
  final WebSocketService webSocketService = WebSocketService();

  bool _isLoading = true;
  bool _isCurrentUserAdmin =
      false; // Add state to track if current user is admin

  // TabController for the tabs
  late TabController _tabController;

  // Group Permission settings (for the second tab)
  bool _allowInviteMembers = false;
  bool _allowRemoveMembers = false;
  bool _allowMemberEdit = false; // Add new permission state

  // Temporary permission states for editing
  bool _tempAllowInviteMembers = false;
  bool _tempAllowRemoveMembers = false;
  bool _tempAllowMemberEdit = false;

  late GroupSettingDTO? _groupSetting;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.conversation.name;
    _imageUrlController.text = widget.conversation.img_url ?? '';
    _groupImageUrl = widget.conversation.img_url;
    print("user id setting ${widget.currentUserId}");
    _chatScreen = ChatScreen(
      conversationId: widget.conversation.id!,
      userId: widget.currentUserId,
      onConversationRemoved: widget.onConversationRemoved,
      updateChatListCallback: widget.updateChatListCallback,
    );

    _tabController = TabController(
      length: widget.conversation.isGroup ? 2 : 1,
      vsync: this,
    );

    _loadParticipants();
    _loadGroupSettings();
  }

  Future<int?> getUser_id() async {
    var user = await _userRepo.GetUserFromApp();
    return user?.id;
  }

  Future<void> _loadParticipants() async {
    setState(() => _isLoading = true);
    try {
      final participants = await _participantsRepo.getParticipants(
        widget.conversation.id!,
      );
      setState(() {
        _participants = participants;

        // Find the current user's participant entry
        final currentUserParticipant = _participants.firstWhere(
          (p) => p.user_id == widget.currentUserId,
          // Provide a default participant if not found to avoid error, including required fields
          orElse:
              () => Participants(
                id: -1,
                conversationId: -1,
                user_id: widget.currentUserId,
                name: 'Unknown',
                joinedAt: DateTime.now(),
                isDeleted: false,
              ), // Added required fields
        );
        // TODO: Implement actual check if current user is admin based on participant data
        // Example placeholder logic (replace with your actual role check):
        // Assuming your Participants model has a field like 'role' or 'isAdmin'
        _isCurrentUserAdmin = currentUserParticipant.role == 'admin';
        print("Current user is admin: $_isCurrentUserAdmin");
        // For now, we'll set it to true for group chats as a placeholder

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading participants: $e')));
    }
  }

  Future<void> _loadGroupSettings() async {
    if (widget.conversation.isGroup) {
      try {
        _groupSetting = await _groupSettingRepo.getGroupSetting(
          widget.conversation.id!,
        );
        setState(() {
          _allowInviteMembers = _groupSetting?.allowMemberInvite ?? false;
          _allowRemoveMembers = _groupSetting?.allowMemberRemove ?? false;
          _allowMemberEdit = _groupSetting?.allowMemberEdit ?? false;

          // Initialize temporary states with current values
          _tempAllowInviteMembers = _allowInviteMembers;
          _tempAllowRemoveMembers = _allowRemoveMembers;
          _tempAllowMemberEdit = _allowMemberEdit;
        });
      } catch (e) {
        print('Error loading group settings: $e');
        // If settings don't exist, create default settings
        try {
          await _groupSettingRepo.createGroupSetting(
            widget.conversation.id!,
            widget.currentUserId,
            _allowInviteMembers,
            _allowMemberEdit,
            _allowRemoveMembers,
          );
        } catch (e) {
          print('Error creating default group settings: $e');
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
      await _uploadImage(image);
    }
  }

  Future<void> _uploadImage(XFile image) async {
    setState(() {
      _isUploading = true;
    });
    try {
      final upload = await _messageRepo.uploadFile(image);
      var fileUrl = upload['fileUrl'];
      if (fileUrl != null) {
        setState(() {
          _groupImageUrl = fileUrl;
          _imageUrlController.text = fileUrl;
          _pickedImage = null;
          _updateGroupImage();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải ảnh lên thất bại: Không nhận được URL'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tải ảnh lên: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _updateGroupImage() {
    try {
      _conversationRepo.updateGroupImage(
        widget.conversation.id!,
        _imageUrlController.text,
      );
      setState(() {
        _groupImageUrl = _imageUrlController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật ảnh nhóm thành công')),
      );
      final newMessage = MessageDTOForAttachment(
        id: DateTime.now().millisecondsSinceEpoch, // ID tạm thời
        senderId: widget.currentUserId,
        content: "Đã cập nhật ảnh đại diện nhóm",
        createdAt: DateTime.now(),
        conversationId: widget.conversation.id!,
        isRead: true,
        isFile: false,
        isRecalled: false,
      );
      var messageWithAttachment = MessageWithAttachment(
        message: newMessage,
        attachment: null,
      );
      widget.updateChatListCallback!(messageWithAttachment);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi cập nhật ảnh nhóm: $e')));
    }
  }

  Future<void> _updateGroupName() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên nhóm không được để trống')),
      );
      return;
    }

    try {
      await _conversationRepo.updateConversationName(
        widget.conversation.id!,
        _nameController.text,
      );
      setState(() {
        widget.conversation.name = _nameController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật tên nhóm thành công')),
      );
      final newMessage = MessageDTOForAttachment(
        id: DateTime.now().millisecondsSinceEpoch, // ID tạm thời
        senderId: widget.currentUserId,
        content: "Đã cập nhật tên nhóm thành ${_nameController.text}",
        createdAt: DateTime.now(),
        conversationId: widget.conversation.id!,
        isRead: true,
        isFile: false,
        isRecalled: false,
      );
      var messageWithAttachment = MessageWithAttachment(
        message: newMessage,
        attachment: null,
      );
      widget.updateChatListCallback!(messageWithAttachment);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi cập nhật tên nhóm: $e')));
    }
  }

  Future<void> _updateNickname() async {
    if (_nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biệt danh không được để trống')),
      );
      return;
    }

    try {
      // Gọi API cập nhật nickname
      await _participantsRepo.updateNickname(
        widget.currentUserId,
        widget.conversation.id!,
        _nicknameController.text,
      );

      // Cập nhật danh sách participants local
      final updatedParticipants = [..._participants];
      final participantIndex = updatedParticipants.indexWhere(
        (p) => p.user_id == widget.currentUserId,
      );

      if (participantIndex != -1) {
        // Tạo participant mới với nickname đã cập nhật
        final updatedParticipant = Participants(
          id: updatedParticipants[participantIndex].id,
          conversationId: updatedParticipants[participantIndex].conversationId,
          user_id: updatedParticipants[participantIndex].user_id,
          joinedAt: updatedParticipants[participantIndex].joinedAt,
          isDeleted: updatedParticipants[participantIndex].isDeleted,
          name: _nicknameController.text,
        );

        updatedParticipants[participantIndex] = updatedParticipant;

        setState(() {
          _participants = updatedParticipants;
        });

        // Cập nhật conversation với participants mới
        final updatedConversation = Conversation(
          id: widget.conversation.id,
          name: widget.conversation.name,
          createdAt: widget.conversation.createdAt,
          isGroup: widget.conversation.isGroup,
          lastMessage: widget.conversation.lastMessage,
          lastMessageTime: widget.conversation.lastMessageTime,
          img_url:
              widget
                  .conversation
                  .img_url, // Keep original image URL when updating nickname
          participants: updatedParticipants,
        );
        // Trả về conversation đã cập nhật để HomeScreen có thể cập nhật
        final newMessage = MessageDTOForAttachment(
          id: DateTime.now().millisecondsSinceEpoch, // ID tạm thời
          senderId: widget.currentUserId,
          content: "Đã cập nhật tên nhóm thành ${_nicknameController.text}",
          createdAt: DateTime.now(),
          conversationId: widget.conversation.id!,
          isRead: true,
          isFile: false,
          isRecalled: false,
        );
        var messageWithAttachment = MessageWithAttachment(
          message: newMessage,
          attachment: null,
        );
        widget.updateChatListCallback!(messageWithAttachment);
        Navigator.pop(context, updatedConversation);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật biệt danh thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi cập nhật biệt danh: $e')));
    }
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Rời nhóm'),
            content: const Text('Bạn có chắc chắn muốn rời khỏi nhóm này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Rời nhóm'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _participantsRepo.leaveGroup(
          widget.conversation.id!,
          widget.currentUserId,
        );
        final newMessage = MessageDTOForAttachment(
          id: DateTime.now().millisecondsSinceEpoch, // ID tạm thời
          senderId: widget.currentUserId,
          content: "Đã rời khỏi nhóm ${widget.conversation.name}",
          createdAt: DateTime.now(),
          conversationId: widget.conversation.id!,
          isRead: true,
          isFile: false,
          isRecalled: false,
        );
        var messageWithAttachment = MessageWithAttachment(
          message: newMessage,
          attachment: null,
        );
        widget.updateChatListCallback!(messageWithAttachment);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi rời nhóm: $e')));
        print("Lỗi khi rời nhóm: $e");
      }
    }
  }

  Future<void> _deleteConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xóa cuộc trò chuyện'),
            content: const Text(
              'Bạn có chắc chắn muốn xóa cuộc trò chuyện này? Hành động này không thể hoàn tác.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      var user = await _userRepo.GetUserFromApp();
      if (user == null) {
        return;
      }
      try {
        await _messageRepo.deleteMessageConversation(
          widget.conversation.id!,
          user.id,
        );
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa cuộc trò chuyện: $e')),
        );
      }
    }
  }

  void _handlePermissionChange(String permissionType, bool value) {
    setState(() {
      switch (permissionType) {
        case 'invite_members':
          _tempAllowInviteMembers = value;
          break;
        case 'remove_members':
          _tempAllowRemoveMembers = value;
          break;
        case 'member_edit':
          _tempAllowMemberEdit = value;
          break;
      }
    });
  }

  Future<void> _submitPermissionChanges() async {
    try {
      final result = await _groupSettingRepo.updateGroupSetting(
        _groupSetting!.id!,
        widget.conversation.id!,
        widget.currentUserId,
        _tempAllowInviteMembers,
        _tempAllowMemberEdit,
        _tempAllowRemoveMembers,
      );

      setState(() {
        _allowInviteMembers = _tempAllowInviteMembers;
        _allowRemoveMembers = _tempAllowRemoveMembers;
        _allowMemberEdit = _tempAllowMemberEdit;
      });

      // Create a system message to notify about permission changes
      final newMessage = MessageDTOForAttachment(
        id: DateTime.now().millisecondsSinceEpoch,
        senderId: widget.currentUserId,
        content:
            "Đã cập nhật quyền nhóm: ${_allowInviteMembers ? 'Cho phép' : 'Không cho phép'} mời thành viên, ${_allowRemoveMembers ? 'Cho phép' : 'Không cho phép'} xóa thành viên, ${_allowMemberEdit ? 'Cho phép' : 'Không cho phép'} chỉnh sửa thông tin",
        createdAt: DateTime.now(),
        conversationId: widget.conversation.id!,
        isRead: true,
        isFile: false,
        isRecalled: false,
      );
      var messageWithAttachment = MessageWithAttachment(
        message: newMessage,
        attachment: null,
      );
      widget.updateChatListCallback!(messageWithAttachment);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi cập nhật quyền nhóm: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper to build the list of tabs based on conditions
  List<Tab> _buildTabs() {
    final tabs = <Tab>[const Tab(text: 'Cài đặt chung')];
    if (widget.conversation.isGroup && _isCurrentUserAdmin) {
      tabs.add(
        const Tab(text: 'Quản lý quyền'),
      ); // Always add the tab if it's a group
    }
    return tabs;
  }

  // Helper to build the list of TabBarView children based on conditions
  List<Widget> _buildTabBarViewChildren() {
    final children = [
      // Tab 1: Cài đặt chung
      ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ), // Adjust padding
        children: [
          // Header Section
          Card(
            margin: EdgeInsets.zero, // Remove margin for integrated look
            shape: RoundedRectangleBorder(
              // Match AppBar's bottom radius
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            clipBehavior: Clip.antiAlias, // Clip content to shape
            elevation: 0, // Remove card elevation to blend with AppBar
            child: Container(
              padding: const EdgeInsets.all(20), // Keep inner padding
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        _pickedImage != null
                            ? FileImage(File(_pickedImage!.path))
                            : (_groupImageUrl != null &&
                                    _groupImageUrl!.isNotEmpty
                                ? NetworkImage(_groupImageUrl!)
                                : null),
                    onBackgroundImageError:
                        _groupImageUrl != null && _groupImageUrl!.isNotEmpty
                            ? (error, stackTrace) {
                              print('Error loading group image: $error');
                            }
                            : null,
                    child:
                        _pickedImage == null &&
                                (_groupImageUrl == null ||
                                    _groupImageUrl!.isEmpty)
                            ? Text(
                              widget.conversation.name.isNotEmpty
                                  ? widget.conversation.name[0].toUpperCase()
                                  : 'G',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            )
                            : null,
                  ),
                  const SizedBox(height: 16), // Adjusted spacing
                  Text(
                    widget.conversation.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color:
                          Colors
                              .black87, // Adjust text color for visibility on lighter background
                    ), // Adjusted spacing
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20), // Added space after header card
          Card(
            margin: const EdgeInsets.symmetric(
              vertical: 8.0,
            ), // Add vertical margin between cards
            elevation: 2.0, // Add a subtle shadow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ), // Rounded corners
            child: _buildSection(
              title: 'Thông tin trò chuyện',
              children: [
                if (widget.conversation.isGroup)
                  _buildSettingTile(
                    title: 'Tên nhóm',
                    subtitle: '',
                    icon: Icons.group,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Nhập tên nhóm',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.right,
                            enabled:
                                _isCurrentUserAdmin || _tempAllowMemberEdit,
                          ),
                        ),
                        if (_isCurrentUserAdmin || _tempAllowMemberEdit)
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            color: Theme.of(context).primaryColor,
                            onPressed: _updateGroupName,
                            tooltip: 'Lưu tên nhóm',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ),
                if (widget.conversation.isGroup)
                  _buildSettingTile(
                    title: 'Ảnh nhóm',
                    subtitle: 'Thay đổi ảnh',
                    icon: Icons.camera_alt_outlined,
                    trailing:
                        _isUploading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : _isCurrentUserAdmin || _tempAllowMemberEdit
                            ? IconButton(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.upload_rounded, size: 20),
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(4),
                                minimumSize: const Size(30, 30),
                              ),
                            )
                            : const Icon(
                              Icons.lock_outline,
                              size: 20,
                              color: Colors.grey,
                            ),
                  ),
                if (!widget.conversation.isGroup)
                  _buildSettingTile(
                    title: 'Biệt danh',
                    subtitle: '',
                    icon: Icons.person,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _nicknameController,
                            decoration: const InputDecoration(
                              hintText: 'Nhập biệt danh',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          color: Theme.of(context).primaryColor,
                          onPressed: _updateNickname,
                          tooltip: 'Lưu biệt danh',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(
              vertical: 8.0,
            ), // Add vertical margin
            elevation: 2.0, // Add a subtle shadow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ), // Rounded corners
            child: _buildSection(
              title: 'Hành động',
              children: [
                _buildSettingTile(
                  title: 'Xem thành viên',
                  subtitle: 'Xem tất cả thành viên trong cuộc trò chuyện',
                  icon: Icons.people,
                  onTap: () async {
                    final userId = await getUser_id(); // Chờ kết quả Future
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MembersScreen(
                              conversation: widget.conversation,
                              participants: _participants,
                              currentUserId: userId ?? 0,
                              groupSetting: _groupSetting!,
                            ),
                      ),
                    );
                  },
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  ), // Add arrow indicator
                ),
                _buildSettingTile(
                  title: 'Tìm kiếm tin nhắn',
                  subtitle: 'Tìm kiếm trong lịch sử trò chuyện',
                  icon: Icons.search,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => SearchMessagesScreen(
                              conversationId: widget.conversation.id!,
                              messages: widget.messages,
                            ),
                      ),
                    );
                  },
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  ), // Add arrow indicator
                ),
              ],
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(
              vertical: 8.0,
            ), // Add vertical margin
            elevation: 2.0, // Add a subtle shadow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ), // Rounded corners
            child: _buildSection(
              title: 'Khu vực nguy hiểm',
              children: [
                if (widget.conversation.isGroup)
                  _buildSettingTile(
                    title: 'Rời nhóm',
                    subtitle: 'Thoát khỏi nhóm này',
                    icon: Icons.exit_to_app,
                    iconColor: Colors.red, // Keep red color for danger action
                    onTap: _leaveGroup,
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.red,
                    ), // Add red arrow indicator
                  ),
                _buildSettingTile(
                  title: 'Xóa cuộc trò chuyện',
                  subtitle: 'Xóa vĩnh viễn cuộc trò chuyện này',
                  icon: Icons.delete,
                  iconColor: Colors.red, // Keep red color for danger action
                  onTap: _deleteConversation,
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.red,
                  ), // Add red arrow indicator
                ),
              ],
            ),
          ),
          const SizedBox(height: 20), // Added space at the bottom
        ],
      ),
    ];

    // Add the second tab content based on conditions
    if (widget.conversation.isGroup && _isCurrentUserAdmin) {
      children.add(
        // Tab 2: Quản lý quyền (Admin view)
        ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ), // Adjust padding
          children: [
            Card(
              margin: const EdgeInsets.symmetric(
                vertical: 8.0,
              ), // Add vertical margin
              elevation: 2.0, // Add a subtle shadow
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ), // Rounded corners
              child: _buildSection(
                title: 'Cài đặt quyền thành viên',
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Quản lý quyền của các thành viên trong nhóm',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPermissionTile(
                    title: 'Mời thành viên',
                    description: 'Cho phép thành viên mời người khác vào nhóm',
                    value: _tempAllowInviteMembers,
                    onChanged:
                        (value) =>
                            _handlePermissionChange('invite_members', value),
                    icon: Icons.person_add_outlined,
                  ),
                  _buildPermissionTile(
                    title: 'Xóa thành viên',
                    description:
                        'Cho phép thành viên xóa thành viên khác khỏi nhóm',
                    value: _tempAllowRemoveMembers,
                    onChanged:
                        (value) =>
                            _handlePermissionChange('remove_members', value),
                    icon: Icons.person_remove_outlined,
                  ),
                  _buildPermissionTile(
                    title: 'Chỉnh sửa thông tin',
                    description: 'Cho phép thành viên thay đổi thông tin nhóm',
                    value: _tempAllowMemberEdit,
                    onChanged:
                        (value) =>
                            _handlePermissionChange('member_edit', value),
                    icon: Icons.edit_outlined,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      onPressed: _submitPermissionChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.save_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Lưu thay đổi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // TODO: Add a save button for permissions if needed, or use the AppBar save button
            // Currently, using the AppBar save button. _savePermissions needs to be called from _saveSettings.
          ],
        ),
      );
    } else if (widget.conversation.isGroup && !_isCurrentUserAdmin) {
      // Tab 2: Message for non-admins in a group
      children.add(
        ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ), // Adjust padding
          children: const [
            Padding(
              padding: EdgeInsets.only(top: 20.0), // Adjust padding
              child: Center(
                child: Text(
                  'Bạn không có quyền quản lý cài đặt nhóm.',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ), // Adjust style and color
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // For non-group chats, add an empty container or similar if TabBarView length is 2 (should be 1)
      // This else case should ideally not be reached if TabBar length is correctly set to 1 for non-groups.
      // children.add(Container()); // Or a specific message
    }

    return children;
  }

  @override
  Widget build(BuildContext context) {
    // Determine the number of tabs based on conditions
    // Fixed logic: If it's a group, there are always 2 tabs. If not, 1 tab.
    // The content of the second tab is conditional.
    final int tabLength = widget.conversation.isGroup ? 2 : 1;

    // Dispose and re-initialize TabController if the length changes.
    // This still might cause a flicker. A cleaner approach might be needed
    // depending on the app's overall architecture and state management.
    if (_tabController.length != tabLength) {
      _tabController.dispose(); // Dispose old controller
      _tabController = TabController(length: tabLength, vsync: this);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final updatedConversation = Conversation(
              id: widget.conversation.id,
              name: widget.conversation.name,
              createdAt: widget.conversation.createdAt,
              isGroup: widget.conversation.isGroup,
              lastMessage: widget.conversation.lastMessage,
              lastMessageTime: widget.conversation.lastMessageTime,
              img_url: _groupImageUrl,
              participants: widget.conversation.participants,
            );
            Navigator.pop(context, updatedConversation);
          },
        ),
        title: Text(
          widget.conversation.isGroup ? 'Cài đặt nhóm' : 'Cài đặt trò chuyện',
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        // Only show TabBar if it's a group chat
        bottom:
            widget.conversation.isGroup
                ? TabBar(
                  controller: _tabController,
                  tabs:
                      _buildTabs(), // Use the helper to build tabs (conditionally includes 'Quản lý quyền' text)
                  labelColor: Colors.white, // Màu chữ khi tab được chọn
                  unselectedLabelColor: Colors.white.withOpacity(
                    0.7,
                  ), // Màu chữ khi tab không được chọn
                  indicatorColor: Colors.white, // Màu gạch chân
                )
                : null, // Don't show TabBar for non-group chats
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(),
              ) // Show loading indicator while participants are loading
              : TabBarView(
                controller: _tabController,
                // Always provide 2 children for TabBarView if tabLength is 2.
                // The content of the second child is determined in _buildTabBarViewChildren.
                children: _buildTabBarViewChildren(),
              ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ), // Adjusted vertical padding
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16, // Slightly smaller font size for section title
              fontWeight: FontWeight.w600, // Slightly less bold
              color: Colors.blueGrey, // More subtle color
            ),
          ),
        ),
        // No Divider here, let Card's border handle separation
        ...children,
      ],
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ), // Adjust content padding
      leading: Icon(
        icon,
        color: iconColor ?? Theme.of(context).primaryColor,
      ), // Use primary color
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ), // Slightly less bold
      subtitle:
          subtitle.isNotEmpty
              ? Text(subtitle, style: TextStyle(color: Colors.grey[600]))
              : null, // Subtle subtitle color
      trailing: trailing, // Use provided trailing widget
      onTap: onTap, // Add tap functionality
      visualDensity: VisualDensity.compact, // Reduce vertical space
    );
  }

  // Add this new function for building permission tile
  Widget _buildPermissionTile({
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
        activeTrackColor: Theme.of(context).primaryColor.withOpacity(0.4),
        inactiveThumbColor: Colors.grey[300],
        inactiveTrackColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _tabController.dispose(); // Dispose TabController
    super.dispose();
  }
}
