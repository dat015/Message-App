import 'dart:io';
import 'dart:typed_data';

import 'package:first_app/data/repositories/Story_repo/story_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class CreateStoryScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatar;

  const CreateStoryScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatar,
  }) : super(key: key);

  @override
  _CreateStoryScreenState createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final StoryRepository _storyRepo = StoryRepository();
  XFile? _imageFile;
  XFile? _videoFile;
  VideoPlayerController? _videoController;
  bool _isUploading = false;
  late AnimationController _loadingController;
  TextEditingController _captionController = TextEditingController();
  
  // Thêm animation cho loading
  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _loadingController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source, 
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _imageFile = image;
          _videoFile = null;
          _videoController?.dispose();
          _videoController = null;
        });
      }
    } catch (e) {
      _showError('Không thể chọn ảnh: $e');
    }
  }

  Future<void> _pickVideo({required ImageSource source}) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 30), // Giới hạn thời lượng video
      );
      if (video != null) {
        final controller = VideoPlayerController.file(File(video.path));
        await controller.initialize();
        setState(() {
          _videoFile = video;
          _imageFile = null;
          _videoController?.dispose();
          _videoController = controller;
          _videoController?.setLooping(true);
          _videoController?.play();
        });
      }
    } catch (e) {
      _showError('Không thể chọn video: $e');
    }
  }

  Future<void> _uploadStory() async {
    if (_imageFile == null && _videoFile == null) {
      _showError('Vui lòng chọn ảnh hoặc video để tiếp tục');
      return;
    }

    setState(() => _isUploading = true);

    try {
      await _storyRepo.createStory(
        authorId: widget.currentUserId,
        authorName: widget.currentUserName,
        authorAvatar: widget.currentUserAvatar,
        imageFile: _imageFile,
        videoFile: _videoFile,
      );

      // Thông báo thành công và trở về màn hình trước
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story đã được đăng thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      _showError('Không thể đăng story: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showOptionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tạo Story mới',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(source: ImageSource.camera);
                    },
                    color: Colors.blueAccent,
                  ),
                  _buildOptionButton(
                    icon: Icons.photo_library,
                    label: 'Thư viện ảnh',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(source: ImageSource.gallery);
                    },
                    color: Colors.purpleAccent,
                  ),
                  _buildOptionButton(
                    icon: Icons.videocam,
                    label: 'Quay video',
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideo(source: ImageSource.camera);
                    },
                    color: Colors.redAccent,
                  ),
                  _buildOptionButton(
                    icon: Icons.video_library,
                    label: 'Thư viện video',
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideo(source: ImageSource.gallery);
                    },
                    color: Colors.orangeAccent,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tạo Story',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_imageFile != null || _videoFile != null)
            TextButton(
              onPressed: _isUploading ? null : _uploadStory,
              child: Text(
                'Đăng',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _isUploading
          ? _buildLoadingView()
          : Stack(
              children: [
                // Preview
                Positioned.fill(
                  child: _buildPreview(),
                ),
                
                // Bottom controls
                if (_imageFile != null || _videoFile != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildEditorControls(),
                  ),
                
                // Floating action button when no media selected
                if (_imageFile == null && _videoFile == null)
                  Positioned.fill(
                    child: Center(
                      child: _buildEmptyState(),
                    ),
                  ),
              ],
            ),
    );
  }
  
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Đang đăng story...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_videoController != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),
      );
    } else if (_imageFile != null) {
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: _imageFile!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  image: DecorationImage(
                    image: MemoryImage(snapshot.data!),
                    fit: BoxFit.contain,
                  ),
                ),
              );
            }
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          },
        );
      } else {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            image: DecorationImage(
              image: FileImage(File(_imageFile!.path)),
              fit: BoxFit.contain,
            ),
          ),
        );
      }
    } else {
      return Container(color: Colors.black);
    }
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.add_photo_alternate,
              size: 40,
              color: Colors.white,
            ),
            onPressed: _showOptionSheet,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tạo story mới',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chia sẻ khoảnh khắc với bạn bè',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildEditorControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Caption input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              controller: _captionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 1,
              decoration: const InputDecoration(
                hintText: 'Thêm chú thích...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Media controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCircleButton(
                icon: Icons.refresh,
                label: 'Chọn lại',
                onPressed: _showOptionSheet,
              ),
              if (_videoController != null)
                _buildCircleButton(
                  icon: _videoController!.value.isPlaying 
                      ? Icons.pause 
                      : Icons.play_arrow,
                  label: _videoController!.value.isPlaying ? 'Tạm dừng' : 'Phát',
                  onPressed: () {
                    setState(() {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
                    });
                  },
                ),
              _buildCircleButton(
                icon: Icons.filter,
                label: 'Bộ lọc',
                onPressed: () {
                  // TODO: Implement filters
                  _showError('Tính năng sẽ sớm ra mắt!');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}