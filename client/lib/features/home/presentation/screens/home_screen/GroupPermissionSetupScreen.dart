import 'package:flutter/material.dart';
import 'package:first_app/data/dto/group_setting_dto.dart';

class GroupPermissionSetupScreen extends StatefulWidget {
  final Function(GroupSettingDTO) onPermissionsSet;
  final int userId;

  const GroupPermissionSetupScreen({
    Key? key,
    required this.onPermissionsSet,
    required this.userId,
  }) : super(key: key);

  @override
  _GroupPermissionSetupScreenState createState() =>
      _GroupPermissionSetupScreenState();
}

class _GroupPermissionSetupScreenState
    extends State<GroupPermissionSetupScreen> {
  bool _allowInviteMembers = false;
  bool _allowRemoveMembers = false;
  bool _allowMemberEdit = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cài đặt quyền nhóm',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.security, color: Colors.white, size: 40),
                      const SizedBox(height: 16),
                      const Text(
                        'Cài đặt quyền nhóm',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Điều chỉnh quyền cho các thành viên trong nhóm của bạn',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Permissions Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quyền thành viên',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPermissionTile(
                        title: 'Mời thành viên',
                        description:
                            'Cho phép thành viên mời người khác vào nhóm',
                        value: _allowInviteMembers,
                        onChanged:
                            (value) =>
                                setState(() => _allowInviteMembers = value),
                        icon: Icons.person_add_outlined,
                      ),
                      _buildPermissionTile(
                        title: 'Xóa thành viên',
                        description:
                            'Cho phép thành viên xóa thành viên khác khỏi nhóm',
                        value: _allowRemoveMembers,
                        onChanged:
                            (value) =>
                                setState(() => _allowRemoveMembers = value),
                        icon: Icons.person_remove_outlined,
                      ),
                      _buildPermissionTile(
                        title: 'Chỉnh sửa thông tin',
                        description:
                            'Cho phép thành viên thay đổi thông tin nhóm',
                        value: _allowMemberEdit,
                        onChanged:
                            (value) => setState(() => _allowMemberEdit = value),
                        icon: Icons.edit_outlined,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Show confirmation dialog
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Xác nhận cài đặt'),
                          content: const Text(
                            'Bạn có chắc chắn muốn lưu cài đặt quyền này cho nhóm?',
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                'Hủy',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Xác nhận',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmed == true) {
                      final settings = GroupSettingDTO(
                        conversationId: 0, // Will be set when group is created
                        allowMemberInvite: _allowInviteMembers,
                        allowMemberEdit: _allowMemberEdit,
                        allowMemberRemove: _allowRemoveMembers,
                        createdBy: widget.userId,
                      );

                      widget.onPermissionsSet(settings);

                      
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Xác nhận cài đặt',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            Icon(icon, color: Colors.blue, size: 24),
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
        activeColor: Colors.blue,
        activeTrackColor: Colors.blue.withOpacity(0.4),
        inactiveThumbColor: Colors.grey[300],
        inactiveTrackColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
