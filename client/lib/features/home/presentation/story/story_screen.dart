import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_app/data/models/story.dart';
import 'package:first_app/data/repositories/Story_repo/story_repo.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class StoryScreen extends StatefulWidget {
  final String currentUserId;
  final List<Story> stories;

  const StoryScreen({
    Key? key,
    required this.currentUserId,
    required this.stories,
  }) : super(key: key);

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  late PageController _pageController;
  late List<VideoPlayerController?> _videoControllers;
  int _currentIndex = 0;
  final StoryRepository _storyRepo = StoryRepository();
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    print('Stories in StoryScreen: ${widget.stories.length}'); // Debug
    if (widget.stories.isEmpty) {
      _videoControllers = [];
      return;
    }
    _pageController = PageController();
    _initializeVideoControllers();
    _markAsViewed(_currentIndex);
  }

  void _initializeVideoControllers() {
    if (widget.stories.isEmpty) {
      _videoControllers = [];
      return;
    }
    _videoControllers = widget.stories.map((story) {
      if (story.isVideo) {
        final controller = VideoPlayerController.network(story.videoUrl!);
        controller.initialize().then((_) => setState(() {}));
        controller.setLooping(true);
        controller.play();
        return controller;
      }
      return null;
    }).toList();
  }

  void _markAsViewed(int index) {
    if (widget.stories.isEmpty || index >= widget.stories.length) return;
    final story = widget.stories[index];
    if (!story.viewers.contains(widget.currentUserId)) {
      _storyRepo.markStoryAsViewed(story.id, widget.currentUserId);
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    for (var controller in _videoControllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Không có story để hiển thị',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.stories.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _showDetails = false;
              });
              _markAsViewed(index);
              if (_videoControllers.isNotEmpty) {
                _videoControllers[_currentIndex]?.play();
                if (_currentIndex > 0) {
                  _videoControllers[_currentIndex - 1]?.pause();
                }
                if (_currentIndex < widget.stories.length - 1) {
                  _videoControllers[_currentIndex + 1]?.pause();
                }
              }
            },
            itemBuilder: (context, index) {
              final story = widget.stories[index];
              return _buildStoryContent(story);
            },
          ),
          _buildHeader(),
          if (_showDetails) _buildStoryDetails(),
        ],
      ),
    );
  }

  Widget _buildStoryContent(Story story) {
    return GestureDetector(
      onTap: () {
        setState(() => _showDetails = !_showDetails);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (story.isImage)
            CachedNetworkImage(
              imageUrl: story.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            )
          else if (story.isVideo && _videoControllers[_currentIndex] != null)
            AspectRatio(
              aspectRatio: _videoControllers[_currentIndex]!.value.aspectRatio,
              child: VideoPlayer(_videoControllers[_currentIndex]!),
            ),
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Row(
        children: List.generate(widget.stories.length, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: LinearProgressIndicator(
                value: _currentIndex == index ? 1.0 : (index < _currentIndex ? 1.0 : 0.0),
                backgroundColor: Colors.grey.withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    final story = widget.stories[_currentIndex];
    final isMyStory = story.authorId == widget.currentUserId;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(story.authorAvatar),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.authorName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatTimeAgo(story.createdAt),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isMyStory)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () => _deleteStory(story),
              ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryDetails() {
    final story = widget.stories[_currentIndex];
    final isMyStory = story.authorId == widget.currentUserId;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMyStory) ...[
              Text(
                'Người xem (${story.viewers.length})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: story.viewers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'User ${story.viewers[index]}', // Thay bằng thông tin thực tế nếu có
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildReactionButton(Icons.favorite, 'Thích'),
                _buildReactionButton(Icons.thumb_up, 'Tuyệt'),
                _buildReactionButton(Icons.sentiment_very_satisfied, 'Haha'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionButton(IconData icon, String label) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: () {
            // Xử lý thêm cảm xúc (có thể lưu vào Firestore)
          },
        ),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  void _deleteStory(Story story) async {
    if (story.authorId != widget.currentUserId) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa story'),
        content: const Text('Bạn có chắc muốn xóa story này?'),
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

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('stories').doc(story.id).delete();
      Navigator.pop(context);
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}