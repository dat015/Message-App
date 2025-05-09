import 'dart:io';
import 'package:first_app/data/repositories/User_Profile_repo/us_profile_repository.dart';
import 'package:first_app/data/repositories/Post_repo/post_repo.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:first_app/data/models/user_profile.dart';

class UpdateAvatarScreen extends StatefulWidget {
  final UserProfile userProfile;
  const UpdateAvatarScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  _UpdateAvatarScreenState createState() => _UpdateAvatarScreenState();
}

class _UpdateAvatarScreenState extends State<UpdateAvatarScreen> {
  File? _selectedImage;
  bool _shareToFeed = false;
  String _visibility = 'public';
  bool _isLoading = false;
  final _picker = ImagePicker();
  final _profileRepo = UsProfileRepository();
  final _postRepo = PostRepo();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateAvatar() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng chọn ảnh'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Upload ảnh lên server
      final imageUrl = await _profileRepo.uploadImage(_selectedImage!);

      // Cập nhật profile với URL ảnh mới
      final updatedProfile = widget.userProfile.copyWith(avatarUrl: imageUrl);
      await _profileRepo.updateUserProfile(updatedProfile);

      // Nếu chọn chia sẻ lên bảng tin
      if (_shareToFeed) {
        await _postRepo.createPost(
          currentUserId: widget.userProfile.id.toString(),
          content: 'Đã cập nhật ảnh đại diện mới!',
          authorName: widget.userProfile.username,
          authorAvatar: imageUrl,
          image: XFile(_selectedImage!.path),
          visibility: _visibility,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Cập nhật ảnh đại diện thành công'),
            ],
          ),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Cập nhật ảnh đại diện',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: _selectedImage != null
                              ? ClipOval(
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: 220,
                                    height: 220,
                                  ),
                                )
                              : widget.userProfile.avatarUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        widget.userProfile.avatarUrl!,
                                        fit: BoxFit.cover,
                                        width: 220,
                                        height: 220,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.person,
                                            size: 100,
                                            color: Colors.grey.shade400,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 100,
                                      color: Colors.grey.shade400,
                                    ),
                        ),
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (context) => Container(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Chọn ảnh từ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildImageSourceOption(
                                            icon: Icons.photo_library,
                                            label: 'Thư viện',
                                            onTap: () {
                                              Navigator.pop(context);
                                              _pickImage();
                                            },
                                          ),
                                          _buildImageSourceOption(
                                            icon: Icons.camera_alt,
                                            label: 'Máy ảnh',
                                            onTap: () {
                                              Navigator.pop(context);
                                              _takePhoto();
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    if (_selectedImage != null)
                      Text(
                        'Ảnh đã được chọn',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    SizedBox(height: 30),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tùy chọn chia sẻ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SwitchListTile(
                              title: Text('Chia sẻ lên bảng tin'),
                              subtitle: Text(
                                'Đăng ảnh này như một bài viết mới',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: _shareToFeed,
                              activeColor: theme.primaryColor,
                              onChanged: (value) => setState(() => _shareToFeed = value),
                            ),
                            if (_shareToFeed) ...[
                              Divider(),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Quyền xem'),
                                trailing: DropdownButton<String>(
                                  value: _visibility,
                                  underline: Container(),
                                  icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'public',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.public, size: 18),
                                          SizedBox(width: 8),
                                          Text('Công khai'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'friends',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.people, size: 18),
                                          SizedBox(width: 8),
                                          Text('Bạn bè'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) => setState(() => _visibility = value!),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateAvatar,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: theme.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'CẬP NHẬT ẢNH ĐẠI DIỆN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}