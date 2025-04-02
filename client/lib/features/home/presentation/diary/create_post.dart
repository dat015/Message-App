import 'dart:io';

import 'package:first_app/data/repositories/Post_repo/post_repo.dart';
import 'package:flutter/foundation.dart'
    show Uint8List, kIsWeb; // Để kiểm tra nếu đang chạy trên web
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'
    if (dart.library.html) 'dart:html'
    as html; // Điều kiện import cho web

class CreatePostScreen extends StatefulWidget {
  final int currentUserId;
  final String currentUserName;

  const CreatePostScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _postController = TextEditingController();
  final PostRepo _postService = PostRepo();
  XFile? _selectedImage;
  String? _selectedMusicUrl;
  List<String> _taggedFriends = [];
  bool _isEditing = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _selectMusic() async {
    // Giả lập chọn nhạc (bạn có thể tích hợp với SelectMusicScreen)
    setState(() {
      _selectedMusicUrl =
          'https://example.com/music.mp3'; // Thay bằng URL thực tế
    });
  }

  Future<void> _tagFriends() async {
    // Giả lập tag bạn bè (bạn có thể mở một màn hình để chọn bạn bè)
    setState(() {
      _taggedFriends = ['friend1', 'friend2']; // Thay bằng danh sách thực tế
    });
  }

  Future<void> _createPost() async {
    try {
      await _postService.createPost(
        content: _postController.text,
        image: _selectedImage,
        musicUrl: _selectedMusicUrl,
        taggedFriends: _taggedFriends,
        currentUserId: widget.currentUserId.toString(),
        authorName: widget.currentUserName,
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tất cả bạn bè'),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.01,
            ),
            child: ElevatedButton(
              onPressed: _isEditing ? _createPost : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEditing ? Colors.blue : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Đăng', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post input area
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: screenWidth * 0.05,
                    backgroundImage: const AssetImage('/images/apple.png'),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: TextField(
                      controller: _postController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Bạn đang nghĩ gì?',
                        border: InputBorder.none,
                      ),
                      style: TextStyle(fontSize: screenWidth * 0.04),
                      onChanged: (value) {
                        setState(() {
                          _isEditing = value.isNotEmpty;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Preview selected image
            if (_selectedImage != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child:
                    kIsWeb
                        ? FutureBuilder<Uint8List>(
                          future: _selectedImage!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return const Icon(Icons.error, color: Colors.red);
                            }
                            if (snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                width: double.infinity,
                                height: screenHeight * 0.3,
                                fit: BoxFit.cover,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        )
                        : Image.file(
                          File(_selectedImage!.path),
                          width: double.infinity,
                          height: screenHeight * 0.3,
                          fit: BoxFit.cover,
                        ),
              ),

            // Preview selected music
            if (_selectedMusicUrl != null)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: 8,
                ),
                child: Text(
                  'Nhạc: $_selectedMusicUrl',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey,
                  ),
                ),
              ),

            // Media options
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Wrap(
                spacing: screenWidth * 0.02,
                runSpacing: screenHeight * 0.01,
                children: [
                  _buildOptionButton(
                    icon: Icons.music_note,
                    label: 'Thêm nhạc',
                    color: Colors.purple,
                    onTap: _selectMusic,
                    screenWidth: screenWidth,
                  ),
                  _buildOptionButton(
                    icon: Icons.photo,
                    label: 'Thêm vào album',
                    color: Colors.green,
                    onTap: _pickImage,
                    screenWidth: screenWidth,
                  ),
                  _buildOptionButton(
                    icon: Icons.tag,
                    label: 'Với bạn bè',
                    color: Colors.grey,
                    onTap: _tagFriends,
                    screenWidth: screenWidth,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenWidth * 0.02,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: screenWidth * 0.05),
            SizedBox(width: screenWidth * 0.02),
            Text(
              label,
              style: TextStyle(color: color, fontSize: screenWidth * 0.035),
            ),
          ],
        ),
      ),
    );
  }
}
