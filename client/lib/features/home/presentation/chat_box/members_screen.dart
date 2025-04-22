import 'package:first_app/data/repositories/User_Repo/user_repo.dart';
import 'package:flutter/material.dart';
import 'package:first_app/data/models/conversation.dart';
import 'package:first_app/data/models/participants.dart';
import 'package:first_app/data/repositories/Participants_Repo/participants_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MembersScreen extends StatefulWidget {
  final Conversation conversation;
  final List<Participants> participants;
  final int currentUserId;

  const MembersScreen({
    super.key,
    required this.conversation,
    required this.participants,
    required this.currentUserId,
  });

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final ParticipantsRepo _participantsRepo = ParticipantsRepo();
  final TextEditingController _searchController = TextEditingController();
  List<Participants> _filteredParticipants = [];
  final UserRepo _userRepo = UserRepo();
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _filteredParticipants = widget.participants;
    print("user id: ${widget.currentUserId}");
  }

  void _filterParticipants(String query) {
    setState(() {
      _filteredParticipants =
          widget.participants.where((participant) {
            final username = participant.name?.toLowerCase();
            final searchLower = query.toLowerCase();
            return username?.contains(searchLower) ?? false;
          }).toList();
    });
  }

  Future<void> _addMember(int userId) async {
    setState(() => _isLoading = true);
    try {
      await _participantsRepo.addMember(widget.conversation.id!, userId);
      // Refresh participants list
      final updatedParticipants = await _participantsRepo.getParticipants(
        widget.conversation.id!,
      );
      setState(() {
        _filteredParticipants = updatedParticipants;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm thành viên thành công')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi thêm thành viên: $e')));
    }
  }

  Future<void> _removeMember(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xóa thành viên'),
            content: const Text('Bạn có chắc chắn muốn xóa thành viên này?'),
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
      setState(() => _isLoading = true);
      try {
        await _participantsRepo.leaveGroup(widget.conversation.id!, userId);
        // Refresh participants list
        final updatedParticipants = await _participantsRepo.getParticipants(
          widget.conversation.id!,
        );
        setState(() {
          _filteredParticipants = updatedParticipants;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa thành viên thành công')),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa thành viên: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thành viên nhóm'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              // Show dialog to add new member
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Thêm thành viên'),
                      content: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Nhập ID người dùng',
                        ),
                        keyboardType: TextInputType.number,
                        onSubmitted: (value) {
                          final userId = int.tryParse(value);
                          if (userId != null) {
                            _addMember(userId);
                            Navigator.pop(context);
                          }
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  widget.conversation.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_filteredParticipants.length} thành viên',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm thành viên...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: _filterParticipants,
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: _filteredParticipants.length,
                      itemBuilder: (context, index) {
                        final participant = _filteredParticipants[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage: NetworkImage(
                                participant.user?.avatarUrl ??
                                    'https://via.placeholder.com/150',
                              ),
                            ),
                            title: Text(
                              participant.name ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              participant.userId == widget.currentUserId
                                  ? 'Bạn'
                                  : 'Thành viên',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing:
                                participant.userId != widget.currentUserId
                                    ? IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () =>
                                              _removeMember(participant.userId),
                                    )
                                    : null,
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
