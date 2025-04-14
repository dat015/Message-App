import 'package:first_app/data/providers/providers.dart';
import 'package:first_app/features/home/presentation/chat_box/chat.dart';
import 'package:first_app/features/home/presentation/screens/members_screen.dart';
import 'package:first_app/features/home/presentation/screens/search_messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:first_app/data/models/conversation.dart';
import 'package:first_app/data/models/participants.dart';
import 'package:first_app/data/repositories/Conversations_repo/conversations_repository.dart';
import 'package:first_app/data/repositories/Participants_Repo/participants_repo.dart';
import 'package:provider/provider.dart';

class ConversationSettingsScreen extends StatefulWidget {
  final Conversation conversation;
  final int currentUserId;

  const ConversationSettingsScreen({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  @override
  State<ConversationSettingsScreen> createState() =>
      _ConversationSettingsScreenState();
}

class _ConversationSettingsScreenState
    extends State<ConversationSettingsScreen> {
  final ConversationRepo _conversationRepo = ConversationRepo();
  final ParticipantsRepo _participantsRepo = ParticipantsRepo();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  late ChatScreen _chatScreen;
  List<Participants> _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.conversation.name;
    _chatScreen = ChatScreen(
      conversationId: widget.conversation.id!,
      userId: widget.currentUserId,
    );
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    setState(() => _isLoading = true);
    try {
      final participants = await _participantsRepo.getParticipants(
        widget.conversation.id!,
      );
      setState(() {
        _participants = participants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading participants: $e')));
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
        (p) => p.userId == widget.currentUserId,
      );

      if (participantIndex != -1) {
        // Tạo participant mới với nickname đã cập nhật
        final updatedParticipant = Participants(
          id: updatedParticipants[participantIndex].id,
          conversationId: updatedParticipants[participantIndex].conversationId,
          userId: updatedParticipants[participantIndex].userId,
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
          participants: updatedParticipants,
        );

        // Trả về conversation đã cập nhật để HomeScreen có thể cập nhật
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
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi rời nhóm: $e')));
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
      try {
        await _conversationRepo.deleteConversation(widget.conversation.id!);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(
              context,
              widget.conversation,
            ); // Trả về conversation đã cập nhật
          },
        ),
        title: Text(
          widget.conversation.isGroup ? 'Cài đặt nhóm' : 'Cài đặt trò chuyện',
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  // Header Section
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Text(
                              widget.conversation.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.conversation.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Settings Sections
                  SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      _buildSection(
                        title: 'Thông tin trò chuyện',
                        children: [
                          if (widget.conversation.isGroup)
                            _buildSettingTile(
                              title: 'Tên nhóm',
                              subtitle: 'Thay đổi tên nhóm',
                              icon: Icons.group,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 150,
                                    child: TextField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        hintText: 'Nhập tên nhóm',
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.save),
                                    onPressed: _updateGroupName,
                                  ),
                                ],
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
                                    width: 150,
                                    child: TextField(
                                      controller: _nicknameController,
                                      decoration: const InputDecoration(
                                        hintText: 'Nhập biệt danh',
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.save),
                                    onPressed: _updateNickname,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      _buildSection(
                        title: 'Hành động',
                        children: [
                          _buildSettingTile(
                            title: 'Xem thành viên',
                            subtitle:
                                'Xem tất cả thành viên trong cuộc trò chuyện',
                            icon: Icons.people,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => MembersScreen(
                                        conversation: widget.conversation,
                                        participants: _participants,
                                        currentUserId: widget.currentUserId,
                                      ),
                                ),
                              );
                            },
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
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      _buildSection(
                        title: 'Khu vực nguy hiểm',
                        children: [
                          if (widget.conversation.isGroup)
                            _buildSettingTile(
                              title: 'Rời nhóm',
                              subtitle: 'Thoát khỏi nhóm này',
                              icon: Icons.exit_to_app,
                              iconColor: Colors.red,
                              onTap: _leaveGroup,
                            ),
                          _buildSettingTile(
                            title: 'Xóa cuộc trò chuyện',
                            subtitle: 'Xóa vĩnh viễn cuộc trò chuyện này',
                            icon: Icons.delete,
                            iconColor: Colors.red,
                            onTap: _deleteConversation,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ]),
                  ),
                ],
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
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
      leading: Icon(icon, color: iconColor ?? Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }
}
