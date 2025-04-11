import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:first_app/data/api/api_jamendo.dart';
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
  // Services and controllers
  final ImagePicker _picker = ImagePicker();
  final StoryRepository _storyRepo = StoryRepository();
  final JamendoService _jamendoService = JamendoService();
  XFile? _imageFile;
  XFile? _videoFile;
  VideoPlayerController? _videoController;
  TextEditingController _captionController = TextEditingController();
  AudioPlayer _audioPlayer = AudioPlayer();

  // Animation and state variables
  late AnimationController _loadingController;
  bool _isUploading = false;
  bool _isMusicPlaying = false;
  
  // Music playback variables
  String? _selectedMusicUrl;
  String? _selectedTrackName;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Duration _startTime = Duration.zero;
  final Duration _maxMusicDuration = const Duration(seconds: 20);

  // Theme colors
  final Color _primaryColor = Colors.blue.shade500;
  final Color _accentColor = Colors.purpleAccent;
  final Color _darkBackground = Color(0xFF121212);
  final Color _cardColor = Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    // Player state listener
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isMusicPlaying = state == PlayerState.playing;
        });
      }
    });

    // Position listener
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          if (_currentPosition >= _startTime + _maxMusicDuration) {
            _audioPlayer.pause();
            _audioPlayer.seek(_startTime);
          }
        });
      }
    });

    // Duration listener
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _videoController?.dispose();
    _loadingController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  // Media picking methods
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
        maxDuration: const Duration(seconds: 30),
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

  // Upload method
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
        musicUrl: _selectedMusicUrl,
        musicStartTime: _startTime.inSeconds,
        musicDuration: _maxMusicDuration.inSeconds,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Story đã được đăng thành công!'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(8),
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
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(8),
      ),
    );
  }

  // Option sheet for media selection
  void _showOptionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Tạo Story mới',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 30),
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
                    color: Colors.blueAccent.shade400,
                  ),
                  _buildOptionButton(
                    icon: Icons.photo_library,
                    label: 'Thư viện ảnh',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(source: ImageSource.gallery);
                    },
                    color: Colors.purpleAccent.shade400,
                  ),
                  _buildOptionButton(
                    icon: Icons.videocam,
                    label: 'Quay video',
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideo(source: ImageSource.camera);
                    },
                    color: Colors.redAccent.shade400,
                  ),
                  _buildOptionButton(
                    icon: Icons.video_library,
                    label: 'Thư viện video',
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideo(source: ImageSource.gallery);
                    },
                    color: Colors.orangeAccent.shade400,
                  ),
                ],
              ),
              SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // Music picker dialog
  void _showMusicPicker() async {
    TextEditingController searchController = TextEditingController();
    String? searchQuery;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Chọn nhạc',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: searchController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm bài hát...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.3),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search, color: _primaryColor),
                            onPressed: () {
                              setModalState(() {
                                searchQuery = searchController.text;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: _primaryColor),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        onSubmitted: (value) {
                          setModalState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _jamendoService.fetchTracks(limit: 20, search: searchQuery),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                              SizedBox(height: 16),
                              Text(
                                'Không thể tải nhạc',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${snapshot.error}',
                                style: TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.music_off, color: Colors.grey, size: 48),
                              SizedBox(height: 16),
                              Text(
                                'Không tìm thấy bài hát nào',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        );
                      }

                      final tracks = snapshot.data!;
                      return ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        itemCount: tracks.length,
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          final isSelected = _selectedMusicUrl == track['audio'];
                          
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? _primaryColor.withOpacity(0.2) : Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: isSelected ? _primaryColor : Colors.grey.shade800,
                                child: Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                track['name'] ?? 'Không có tiêu đề',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                track['artist_name'] ?? 'Không rõ nghệ sĩ',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle, color: _primaryColor)
                                  : Icon(Icons.play_circle_outline, color: Colors.white70),
                              onTap: () async {
                                setState(() {
                                  _selectedMusicUrl = track['audio'];
                                  _selectedTrackName = track['name'];
                                  _startTime = Duration.zero;
                                });
                                await _audioPlayer.play(UrlSource(track['audio']));
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _cardColor.withOpacity(0),
                        _cardColor,
                      ],
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: Size(double.infinity, 0),
                      elevation: 8,
                      shadowColor: _primaryColor.withOpacity(0.5),
                    ),
                    child: Text(
                      'Xong',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
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
      backgroundColor: _darkBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Tạo Story',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close, color: Colors.white, size: 20),
          ),
          onPressed: () {
            _audioPlayer.stop();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (_imageFile != null || _videoFile != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: AnimatedOpacity(
                opacity: _isUploading ? 0.5 : 1.0,
                duration: Duration(milliseconds: 300),
                child: TextButton(
                  onPressed: _isUploading ? null : _uploadStory,
                  style: TextButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Đăng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.send, size: 16),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isUploading
          ? _buildLoadingView()
          : Stack(
              children: [
                Positioned.fill(
                  child: _buildPreview(),
                ),
                if (_imageFile != null || _videoFile != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildEditorControls(),
                  ),
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
    return Container(
      color: _darkBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                      strokeWidth: 3,
                      backgroundColor: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        color: _primaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Đang đăng story...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_videoController != null) {
      return Container(
        color: _darkBackground,
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
                  color: _darkBackground,
                  image: DecorationImage(
                    image: MemoryImage(snapshot.data!),
                    fit: BoxFit.contain,
                  ),
                ),
              );
            }
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            );
          },
        );
      } else {
        return Container(
          decoration: BoxDecoration(
            color: _darkBackground,
            image: DecorationImage(
              image: FileImage(File(_imageFile!.path)),
              fit: BoxFit.contain,
            ),
          ),
        );
      }
    } else {
      return Container(color: _darkBackground);
    }
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.add_photo_alternate,
              size: 50,
              color: _primaryColor,
            ),
            onPressed: _showOptionSheet,
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Tạo story mới',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Chia sẻ khoảnh khắc với bạn bè',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 40),
        ElevatedButton(
          onPressed: _showOptionSheet,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 8,
            shadowColor: _primaryColor.withOpacity(0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add),
              SizedBox(width: 8),
              Text(
                'Bắt đầu ngay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
            Colors.black.withOpacity(0.9),
          ],
          stops: [0.0, 0.8],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedMusicUrl != null) ...[
            Row(
              children: [
                Icon(Icons.music_note, color: _primaryColor, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selectedTrackName ?? "Nhạc đã chọn"}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(18),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: _primaryColor,
                  inactiveTrackColor: Colors.grey.shade800,
                  thumbColor: Colors.white,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayColor: _primaryColor.withOpacity(0.2),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: _currentPosition.inSeconds.toDouble(),
                  min: 0,
                  max: _totalDuration.inSeconds.toDouble(),
                  onChanged: (value) {
                    final newPosition = Duration(seconds: value.toInt());
                    _audioPlayer.seek(newPosition);
                    setState(() {
                      _startTime = newPosition;
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(
                    _formatDuration(_currentPosition),
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    _formatDuration(_totalDuration),
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 24),
          Container(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              children: [
                _buildCircleButton(
                  icon: Icons.refresh,
                  label: 'Chọn lại',
                  onPressed: _showOptionSheet,
                  color: Colors.white,
                ),
                if (_videoController != null)
                  _buildCircleButton(
                    icon: _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    label: _videoController!.value.isPlaying ? 'Tạm dừng' : 'Phát',
                    onPressed: () {
                      setState(() {
                        _videoController!.value.isPlaying
                            ? _videoController!.pause()
                            : _videoController!.play();
                      });
                    },
                    color: Colors.greenAccent,
                  ),
                _buildCircleButton(
                  icon: Icons.music_note,
                  label: 'Thêm nhạc',
                  onPressed: _showMusicPicker,
                  color: _accentColor,
                ),
                if (_selectedMusicUrl != null)
                  _buildCircleButton(
                    icon: _isMusicPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    label: _isMusicPlaying ? 'Dừng nhạc' : 'Phát nhạc',
                    onPressed: () {
                      if (_isMusicPlaying) {
                        _audioPlayer.pause();
                      } else {
                        _audioPlayer.seek(_startTime);
                        _audioPlayer.resume();
                      }
                    },
                    color: _primaryColor,
                  ),
                _buildCircleButton(
                  icon: Icons.filter,
                  label: 'Bộ lọc',
                  onPressed: () {
                    _showFilterOptions();
                  },
                  color: Colors.orangeAccent,
                ),
                _buildCircleButton(
                  icon: Icons.text_fields,
                  label: 'Thêm chữ',
                  onPressed: () {
                    _showTextEditor();
                  },
                  color: Colors.pinkAccent,
                ),
                _buildCircleButton(
                  icon: Icons.emoji_emotions,
                  label: 'Sticker',
                  onPressed: () {
                    _showError('Tính năng sẽ sớm ra mắt!');
                  },
                  color: Colors.amberAccent,
                ),
                _buildCircleButton(
                  icon: Icons.brush,
                  label: 'Vẽ',
                  onPressed: () {
                    _showError('Tính năng sẽ sớm ra mắt!');
                  },
                  color: Colors.purpleAccent,
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          
          // Upload button at bottom
          Container(
            margin: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: ElevatedButton(
              onPressed: _isUploading ? null : _uploadStory,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                shadowColor: _primaryColor.withOpacity(0.5),
                minimumSize: Size(double.infinity, 0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_rounded),
                  SizedBox(width: 8),
                  Text(
                    'Đăng Story',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    final List<String> filters = [
      'Gốc', 'Ấm', 'Lạnh', 'Hoài niệm', 'Đen trắng', 'Sống động', 'Mềm mại', 'Contrast'
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 280,
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Chọn bộ lọc',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  return Container(
                    width: 100,
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            color: index == 0 ? null : Colors.primaries[index % Colors.primaries.length].withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            image: _imageFile != null 
                                ? DecorationImage(
                                    image: FileImage(File(_imageFile!.path)),
                                    fit: BoxFit.cover,
                                    colorFilter: index == 0 
                                        ? null 
                                        : ColorFilter.matrix(_getColorMatrix(filters[index])),
                                  )
                                : null,
                          ),
                          child: _imageFile == null 
                              ? Center(child: Icon(Icons.image, color: Colors.white54)) 
                              : null,
                        ),
                        SizedBox(height: 8),
                        Text(
                          filters[index],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<double> _getColorMatrix(String filter) {
    // Demo color matrices - in a real app would implement actual filters
    switch (filter) {
      case 'Đen trắng':
        return [
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case 'Ấm':
        return [
          1.2, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 0.8, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case 'Lạnh':
        return [
          0.8, 0, 0, 0, 0,
          0, 0.9, 0, 0, 0,
          0, 0, 1.2, 0, 0,
          0, 0, 0, 1, 0,
        ];
      default:
        return [
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ];
    }
  }

  void _showTextEditor() {
    TextEditingController textController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Thêm văn bản',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: textController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nhập văn bản của bạn...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor),
                    ),
                  ),
                  maxLines: 3,
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Hủy'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (textController.text.isNotEmpty) {
                            // Apply text to story
                            _showError('Đã thêm văn bản vào story');
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Thêm'),
                      ),
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      width: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            margin: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.7), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(30),
                splashColor: color.withOpacity(0.3),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}