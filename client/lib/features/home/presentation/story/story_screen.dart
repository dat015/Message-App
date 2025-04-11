import 'package:audioplayers/audioplayers.dart';
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

class _StoryScreenState extends State<StoryScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late List<VideoPlayerController?> _videoControllers;
  late AudioPlayer _audioPlayer;
  int _currentIndex = 0;
  final StoryRepository _storyRepo = StoryRepository();
  bool _showDetails = false;
  bool _isLikeAnimating = false;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  final Duration _storyDuration = const Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    print('Stories in StoryScreen: ${widget.stories.length}');
    _audioPlayer = AudioPlayer();
    if (widget.stories.isEmpty) {
      _videoControllers = [];
      return;
    }
    _pageController = PageController();
    _initializeVideoControllers();
    _markAsViewed(_currentIndex);

    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    );

    _progressAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_progressController)
          ..addListener(() {
            if (mounted) setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _nextStory();
            }
          });

    _playCurrentStoryMedia();
  }

  void _nextStory() {
    _progressController.stop();
    _progressController.reset();

    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _markAsViewed(_currentIndex);
      _playCurrentStoryMedia();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _progressController.stop();
      _progressController.reset();

      setState(() {
        _currentIndex--;
      });
      _markAsViewed(_currentIndex);
      _playCurrentStoryMedia();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _initializeVideoControllers() {
    if (widget.stories.isEmpty) {
      _videoControllers = [];
      return;
    }
    _videoControllers =
        widget.stories.map((story) {
          if (story.isVideo) {
            final controller = VideoPlayerController.network(story.videoUrl!);
            controller
                .initialize()
                .then((_) {
                  if (mounted) setState(() {});
                })
                .catchError((e) {
                  print('Error initializing video: $e');
                });
            controller.setLooping(false);
            controller.addListener(() {
              if (controller.value.isInitialized) {
                final position = controller.value.position;
                if (position >= _storyDuration ||
                    position >= controller.value.duration) {
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
      _storyRepo.markStoryAsViewed(story.id, widget.currentUserId).catchError((
        e,
      ) {
        print('Error marking story as viewed: $e');
      });
    }
  }

  Future<void> _playCurrentStoryMedia() async {
    final story = widget.stories[_currentIndex];

    // Dừng tất cả media trước khi phát mới
    await _audioPlayer.stop();
    for (var controller in _videoControllers) {
      controller?.pause();
    }
    _progressController.reset();

    // Phát video nếu có
    if (story.isVideo && _videoControllers[_currentIndex] != null) {
      final controller = _videoControllers[_currentIndex]!;
      await controller.play().catchError((e) {
        print('Error playing video: $e');
      });
      Future.delayed(_storyDuration, () {
        if (mounted && controller.value.isPlaying) {
          _nextStory();
        }
      });
    }

    // Phát nhạc nếu có musicUrl
    if (story.musicUrl != null && story.musicUrl!.isNotEmpty) {
      final startTime = Duration(seconds: story.musicStartTime ?? 0);
      final duration = Duration(seconds: story.musicDuration ?? 15);

      try {
        print('Streaming music from: ${story.musicUrl}');
        await _audioPlayer.setSourceUrl(story.musicUrl!);
        await _audioPlayer.seek(startTime);
        await _audioPlayer.resume();

        _audioPlayer.onPlayerStateChanged.listen((state) {
          if (mounted &&
              state == PlayerState.playing &&
              !_progressController.isAnimating) {
            _progressController.duration = duration;
            _progressController.forward(from: 0.0);
          }
        });

        _audioPlayer.onPositionChanged.listen((position) {
          if (mounted && position >= startTime + duration) {
            _audioPlayer.pause();
            _nextStory();
          }
        });
      } catch (e) {
        print('Error playing audio: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Không thể phát nhạc: $e')));
        }
      }
    } else if (story.isImage && story.musicUrl == null) {
      _progressController.duration = _storyDuration;
      _progressController.forward();
    }
  }

  void _handlePageChange(int index) {
    setState(() {
      _currentIndex = index;
      _showDetails = false;
    });
    _markAsViewed(index);
    _playCurrentStoryMedia();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    for (var controller in _videoControllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return _buildEmptyStoryScreen();
    }

    final story = widget.stories[_currentIndex];
    final hasLiked = story.reactions.containsKey(widget.currentUserId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tapPosition = details.globalPosition.dx;
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
        onDoubleTap: () {
          if (!hasLiked) {
            _toggleLike(story);
            setState(() {
              _isLikeAnimating = true;
            });
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                setState(() {
                  _isLikeAnimating = false;
                });
              }
            });
          }
        },
        onLongPress: () {
          setState(() => _showDetails = true);
          _pauseMedia();
        },
        onLongPressUp: () {
          setState(() => _showDetails = false);
          _resumeMedia();
        },
        child: Stack(
          children: [
            // Content area
            PageView.builder(
              controller: _pageController,
              itemCount: widget.stories.length,
              onPageChanged: _handlePageChange,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return _buildStoryContent(story, index);
              },
            ),

            // Progress indicators
            _buildProgressIndicators(),

            // Header with author info
            _buildHeader(),

            // Reaction button
            _buildReactionButton(story, hasLiked),

            // Viewers count
            _buildViewersButton(story),

            // Details overlay when long-pressed
            if (_showDetails) _buildStoryDetails(),

            // Like animation on double tap
            if (_isLikeAnimating) _buildLikeAnimation(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStoryScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white10,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_album_outlined,
                color: Colors.white,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Không có story để hiển thị',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy quay lại sau',
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white12,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                elevation: 0,
              ),
              child: const Text('Quay lại', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _pauseMedia() {
    final story = widget.stories[_currentIndex];
    if (story.isVideo && _videoControllers[_currentIndex] != null) {
      _videoControllers[_currentIndex]!.pause();
    }
    if (story.musicUrl != null) {
      _audioPlayer.pause();
    }
    if (story.isImage && story.musicUrl == null) {
      _progressController.stop();
    }
  }

  void _resumeMedia() {
    final story = widget.stories[_currentIndex];
    if (story.isVideo && _videoControllers[_currentIndex] != null) {
      _videoControllers[_currentIndex]!.play();
    }
    if (story.musicUrl != null) {
      _audioPlayer.resume();
    }
    if (story.isImage && story.musicUrl == null) {
      _progressController.forward();
    }
  }

  Widget _buildStoryContent(Story story, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
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
                placeholder:
                    (context, url) => Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.grey[900],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Không thể tải ảnh',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
            )
          else if (story.isVideo &&
              index == _currentIndex &&
              _videoControllers[index] != null)
            _videoControllers[index]!.value.isInitialized
                ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoControllers[index]!.value.size.width,
                    height: _videoControllers[index]!.value.size.height,
                    child: VideoPlayer(_videoControllers[index]!),
                  ),
                )
                : const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
          // Top gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                stops: const [0.0, 0.8],
              ),
            ),
          ),
          // Bottom gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                stops: const [0.0, 0.8],
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
            final story = widget.stories[index];
            if (story.isVideo &&
                _videoControllers[index]?.value.isInitialized == true) {
              final controller = _videoControllers[index]!;
              value = (controller.value.position.inSeconds /
                      _storyDuration.inSeconds)
                  .clamp(0.0, 1.0);
            } else {
              value = _progressAnimation.value;
            }
          }
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.withOpacity(0.4),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 4,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    if (widget.stories.isEmpty || _currentIndex >= widget.stories.length)
      return Container();

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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 20,
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
                      shadows: [
                        Shadow(
                          blurRadius: 8.0,
                          color: Colors.black,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimeAgo(story.createdAt),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          shadows: [
                            Shadow(
                              blurRadius: 4.0,
                              color: Colors.black,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isMyStory)
              _buildHeaderButton(
                icon: Icons.delete_outline,
                onPressed: () => _deleteStory(story),
              ),
            const SizedBox(width: 8),
            _buildHeaderButton(
              icon: Icons.close,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
        style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
      ),
    );
  }

  Widget _buildReactionButton(Story story, bool hasLiked) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _toggleLike(story),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasLiked ? Icons.favorite : Icons.favorite_border,
                          color: hasLiked ? Colors.red : Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${story.reactions.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildViewersButton(Story story) {
    return Positioned(
      bottom: 16,
      left: 16,
      child: GestureDetector(
        onTap: () {
          if (story.viewers.isNotEmpty) {
            _showViewersModal(story);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const Icon(Icons.visibility, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                '${story.viewers.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showViewersModal(Story story) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Người xem (${story.viewers.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24),
                if (story.viewers.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.visibility_off,
                            size: 48,
                            color: Colors.white38,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có người xem',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: Future.wait(
                        story.viewers
                            .map((viewerId) => _storyRepo.getUserInfo(viewerId))
                            .toList(),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Center(
                            child: Text(
                              'Lỗi khi tải danh sách người xem',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        final userInfos = snapshot.data!;
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: story.viewers.length,
                          itemBuilder: (context, index) {
                            final viewerId = story.viewers[index];
                            final userInfo = userInfos[index];
                            final hasLiked = story.reactions.containsKey(
                              viewerId,
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage:
                                        userInfo['avatar'].isNotEmpty
                                            ? NetworkImage(userInfo['avatar'])
                                            : null,
                                    child:
                                        userInfo['avatar'].isEmpty
                                            ? const Icon(
                                              Icons.person,
                                              size: 24,
                                              color: Colors.white,
                                            )
                                            : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userInfo['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (hasLiked)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.visibility,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
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
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child:
                      story.viewers.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.visibility_off,
                                  color: Colors.white38,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Chưa có người xem',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            itemCount: story.viewers.length,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.blueGrey[700],
                                      child: const Icon(
                                        Icons.person,
                                        size: 28,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'User ${story.viewers[index].substring(0, 4)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedReactionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color activeColor = Colors.blue,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLikeAnimation() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 2.0 * value > 1.0 ? 2.0 - value : value,
            child: Opacity(
              opacity: value > 0.8 ? (1.0 - value) * 5 : value,
              child: const Icon(Icons.favorite, color: Colors.red, size: 100),
            ),
          );
        },
      ),
    );
  }

  void _toggleLike(Story story) async {
    final hasLiked = story.reactions.containsKey(widget.currentUserId);

    try {
      if (hasLiked) {
        await _storyRepo.removeReaction(story.id, widget.currentUserId);
        setState(() {
          final updatedReactions = Map<String, String>.from(story.reactions)
            ..remove(widget.currentUserId);
          widget.stories[_currentIndex] = Story(
            id: story.id,
            authorId: story.authorId,
            authorName: story.authorName,
            authorAvatar: story.authorAvatar,
            imageUrl: story.imageUrl,
            videoUrl: story.videoUrl,
            musicUrl: story.musicUrl,
            musicStartTime: story.musicStartTime,
            musicDuration: story.musicDuration,
            createdAt: story.createdAt,
            expiresAt: story.expiresAt,
            viewers: story.viewers,
            reactions: updatedReactions,
          );
        });
      } else {
        await _storyRepo.addReaction(story.id, widget.currentUserId, 'like');
        setState(() {
          widget.stories[_currentIndex] = Story(
            id: story.id,
            authorId: story.authorId,
            authorName: story.authorName,
            authorAvatar: story.authorAvatar,
            imageUrl: story.imageUrl,
            videoUrl: story.videoUrl,
            musicUrl: story.musicUrl,
            musicStartTime: story.musicStartTime,
            musicDuration: story.musicDuration,
            createdAt: story.createdAt,
            expiresAt: story.expiresAt,
            viewers: story.viewers,
            reactions: {...story.reactions, widget.currentUserId: 'like'},
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _deleteStory(Story story) async {
    if (story.authorId != widget.currentUserId) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Xóa story',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red[300],
                    size: 48,
                  ),
                ),
                SizedBox(height: 16),
                const Text(
                  'Bạn có chắc muốn xóa story này?',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text(
                  'Xóa',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Center(
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ),
      );

      try {
        await FirebaseFirestore.instance
            .collection('stories')
            .doc(story.id)
            .delete();
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context); // Close story screen

        // Hiển thị thông báo xóa thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã xóa story thành công'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    }
    return 'Vừa xong';
  }
}
