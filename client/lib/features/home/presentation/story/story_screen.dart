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

class _StoryScreenState extends State<StoryScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late List<VideoPlayerController?> _videoControllers;
  int _currentIndex = 0;
  final StoryRepository _storyRepo = StoryRepository();
  bool _showDetails = false;
  
  // Animation controllers
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  final Duration _storyDuration = const Duration(seconds: 15);
  
  @override
  void initState() {
    super.initState();
    print('Stories in StoryScreen: ${widget.stories.length}');
    if (widget.stories.isEmpty) {
      _videoControllers = [];
      return;
    }
    _pageController = PageController();
    _initializeVideoControllers();
    _markAsViewed(_currentIndex);
    
    // Initialize animation controller for story progress
    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_progressController)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStory();
        }
      });
    
    // Start progress for image stories
    if (widget.stories.isNotEmpty && !widget.stories[_currentIndex].isVideo) {
      _progressController.forward();
    }
  }
  
  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _initializeVideoControllers() {
    if (widget.stories.isEmpty) {
      _videoControllers = [];
      return;
    }
    _videoControllers = widget.stories.map((story) {
      if (story.isVideo) {
        final controller = VideoPlayerController.network(story.videoUrl!);
        controller.initialize().then((_) {
          setState(() {});
          // For videos, use the video's own duration instead of the fixed duration
          controller.play();
        });
        controller.setLooping(false);
        controller.addListener(() {
          // Update progress based on video position
          if (controller.value.isInitialized) {
            final progress = controller.value.position.inMilliseconds / 
                          controller.value.duration.inMilliseconds;
            if (progress >= 1.0) {
              _nextStory();
            }
          }
        });
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
  
  void _handlePageChange(int index) {
    setState(() {
      _currentIndex = index;
      _showDetails = false;
    });
    _markAsViewed(index);
    
    // Reset and restart progress animation
    _progressController.reset();
    
    // Handle video controllers
    if (_videoControllers.isNotEmpty) {
      // Pause all videos first
      for (var controller in _videoControllers) {
        controller?.pause();
      }
      
      // Play current video if available
      if (widget.stories[index].isVideo && _videoControllers[index] != null) {
        _videoControllers[index]!.play();
      } else {
        // Start progress for image stories
        _progressController.forward();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_album_outlined, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              Text(
                'Không có story để hiển thị',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white12,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tapPosition = details.globalPosition.dx;
          
          // Tap on left 1/3 of screen to go back, right 2/3 to go forward
          if (tapPosition < screenWidth / 3) {
            _previousStory();
          } else {
            if (!_showDetails) {
              _nextStory();
            } else {
              setState(() => _showDetails = false);
            }
          }
        },
        onLongPress: () {
          setState(() => _showDetails = true);
          // Pause progress/video when showing details
          if (widget.stories[_currentIndex].isVideo) {
            _videoControllers[_currentIndex]?.pause();
          } else {
            _progressController.stop();
          }
        },
        onLongPressUp: () {
          setState(() => _showDetails = false);
          // Resume progress/video when hiding details
          if (widget.stories[_currentIndex].isVideo) {
            _videoControllers[_currentIndex]?.play();
          } else {
            _progressController.forward();
          }
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.stories.length,
              onPageChanged: _handlePageChange,
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return _buildStoryContent(story, index);
              },
            ),
            _buildProgressIndicators(),
            _buildHeader(),
            if (_showDetails) _buildStoryDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(Story story, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (story.isImage)
            Hero(
              tag: 'story_${story.id}',
              child: CachedNetworkImage(
                imageUrl: story.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(Icons.error_outline, color: Colors.white, size: 48),
                  ),
                ),
              ),
            )
          else if (story.isVideo && index == _currentIndex && _videoControllers[index] != null)
            Center(
              child: AspectRatio(
                aspectRatio: _videoControllers[index]!.value.isInitialized
                    ? _videoControllers[index]!.value.aspectRatio
                    : 16 / 9,
                child: VideoPlayer(_videoControllers[index]!),
              ),
            ),
          // Add gradient overlays for better readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicators() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 8,
      right: 8,
      child: Row(
        children: List.generate(widget.stories.length, (index) {
          double value;
          if (index < _currentIndex) {
            value = 1.0;
          } else if (index > _currentIndex) {
            value = 0.0;
          } else {
            // Current story
            if (widget.stories[index].isVideo && _videoControllers[index]?.value.isInitialized == true) {
              // For videos, use video position
              final controller = _videoControllers[index]!;
              value = controller.value.position.inMilliseconds / 
                    controller.value.duration.inMilliseconds;
            } else {
              // For images, use animation progress
              value = _progressAnimation.value;
            }
          }
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey.withOpacity(0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 3,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    if (widget.stories.isEmpty || _currentIndex >= widget.stories.length) return Container();
    
    final story = widget.stories[_currentIndex];
    final isMyStory = story.authorId == widget.currentUserId;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(story.authorAvatar),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    story.authorName,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTimeAgo(story.createdAt),
                    style: const TextStyle(
                      color: Colors.white70, 
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            if (isMyStory)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black26,
                  padding: const EdgeInsets.all(8),
                ),
                onPressed: () => _deleteStory(story),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 22),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black26,
                padding: const EdgeInsets.all(8),
              ),
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.6),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMyStory) ...[
                Row(
                  children: [
                    const Icon(Icons.visibility, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Người xem (${story.viewers.length})',
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: story.viewers.isEmpty
                      ? const Center(
                          child: Text(
                            'Chưa có người xem',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: story.viewers.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.white24,
                                    child: Icon(Icons.person, size: 18, color: Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'User ${story.viewers[index]}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildReactionButton(Icons.favorite_border, 'Thích'),
                    _buildReactionButton(Icons.thumb_up_alt_outlined, 'Tuyệt'),
                    _buildReactionButton(Icons.sentiment_very_satisfied_outlined, 'Haha'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // User reaction & comment input box
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Phản hồi...',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: () {
                        // Implement send functionality
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionButton(IconData icon, String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Handle reaction
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                label, 
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteStory(Story story) async {
    if (story.authorId != widget.currentUserId) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Xóa story', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bạn có chắc muốn xóa story này?',
          style: TextStyle(color: Colors.white70),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
        ),
      );
      
      try {
        await FirebaseFirestore.instance.collection('stories').doc(story.id).delete();
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context); // Close story screen
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}