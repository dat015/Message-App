import 'dart:io';
import 'package:first_app/PlatformClient/config.dart';
import 'package:first_app/data/repositories/Map_Repo/map_repo.dart';
import 'package:first_app/features/home/presentation/diary/location_post/place_selection_screen.dart';
import 'package:first_app/features/home/presentation/diary/location_post/post_location_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:latlong2/latlong.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:first_app/data/repositories/Post_repo/post_repo.dart';
import 'package:first_app/features/home/presentation/ai_caption/bloc_post/ai_caption_bloc.dart';
import 'package:first_app/data/repositories/AI_Post_Repo/ai_post_request_repo.dart';
import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/features/home/presentation/ai_caption/ai_caption_screen.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;

class CreatePostScreen extends StatefulWidget {
  final int currentUserId;
  final String currentUserName;
  final String currentUserAvatar;

  const CreatePostScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatar,
  }) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _postController = TextEditingController();
  final PostRepo _postService = PostRepo();
  final LocationRepo _locationService = LocationRepo();
  XFile? _selectedImage;
  String? _selectedMusicUrl;
  List<String> _taggedFriends = [];
  bool _isEditing = false;
  bool _isPosting = false;
  String _visibility = 'public';
  latlong.LatLng? _selectedLocation;
  String? _selectedAddress;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _selectMusic() async {
    setState(() {
      _selectedMusicUrl = 'https://example.com/music.mp3';
    });
  }

  Future<void> _removeMusic() async {
    setState(() {
      _selectedMusicUrl = null;
    });
  }

  Future<void> _tagFriends() async {
    setState(() {
      _taggedFriends = ['Nguyễn Văn A', 'Trần Thị B'];
    });
  }

  Future<void> _removeLocation() async {
    setState(() {
      _selectedLocation = null;
      _selectedAddress = null;
    });
  }

  Future<void> _pickCurrentLocation() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng bật quyền trong cài đặt.')),
      );
      return;
    }

    Position? position = await _locationService.getCurrentLocation();
    if (position != null) {
      String? address = await _locationService.getAddressFromLatLng(position.latitude, position.longitude);
      if (address != null) {
        setState(() {
          _selectedLocation = latlong.LatLng(position.latitude, position.longitude);
          _selectedAddress = address;
        });
        _showLocationPicker(position);
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi khi lấy vị trí: $e')),
    );
  }
}

void _showLocationPicker(Position position) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (context) => LocationPicker(
      initialPosition: latlong.LatLng(position.latitude, position.longitude),
      onLocationSelected: (latlong.LatLng latLng, String address) {
        setState(() {
          _selectedLocation = latLng;
          _selectedAddress = address;
        });
      },
    ),
  );
}

  Future<void> _showPlacePicker() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PlacePickerScreen(
              locationService: _locationService,
              onLocationSelected: (LatLng latLng, String address) {
                setState(() {
                  _selectedLocation = latLng;
                  _selectedAddress = address;
                });
              },
            ),
      ),
    );
  }

  Future<void> _createPost() async {
    if (_postController.text.isEmpty &&
        _selectedImage == null &&
        _selectedMusicUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm nội dung, ảnh hoặc nhạc vào bài viết'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      await _postService.createPost(
        content: _postController.text,
        image: _selectedImage,
        musicUrl: _selectedMusicUrl,
        taggedFriends: _taggedFriends,
        currentUserId: widget.currentUserId.toString(),
        authorAvatar: widget.currentUserAvatar,
        authorName: widget.currentUserName,
        visibility: _visibility,
        location:
            _selectedLocation != null
                ? {
                  'latitude': _selectedLocation!.latitude,
                  'longitude': _selectedLocation!.longitude,
                  'address': _selectedAddress,
                }
                : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng bài viết thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi đăng bài: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  void _showAiCaptionBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder:
          (context) => BlocProvider(
            create:
                (context) => AiCaptionBloc(
                  AiCaptionService(ApiClient(baseUrl: Config.baseUrl)),
                ),
            child: AiCaptionBottomSheet(
              onCaptionSelected: (caption) {
                setState(() {
                  _postController.text = caption;
                  _isEditing = true;
                });
              },
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tạo bài viết',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.045,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.01,
            ),
            child: ElevatedButton(
              onPressed:
                  (_isEditing ||
                              _selectedImage != null ||
                              _selectedMusicUrl != null ||
                              _selectedLocation != null) &&
                          !_isPosting
                      ? _createPost
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    (_isEditing ||
                            _selectedImage != null ||
                            _selectedMusicUrl != null ||
                            _selectedLocation != null)
                        ? primaryColor
                        : Colors.grey[300],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.005,
                ),
              ),
              child:
                  _isPosting
                      ? SizedBox(
                        width: screenWidth * 0.04,
                        height: screenWidth * 0.04,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        'Đăng',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(height: 1, thickness: 0.5, color: Colors.grey[300]),
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: screenWidth * 0.06,
                        backgroundImage: NetworkImage(widget.currentUserAvatar),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.currentUserName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.04,
                                ),
                              ),
                              if (_taggedFriends.isNotEmpty) ...[
                                Text(
                                  ' cùng với ',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.035,
                                  ),
                                ),
                                Text(
                                  '${_taggedFriends.length} người khác',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      _taggedFriends = [];
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.02,
                              vertical: screenWidth * 0.01,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _visibility,
                                isDense: true,
                                icon: Icon(
                                  _visibility == 'public'
                                      ? Icons.public
                                      : Icons.group,
                                  size: screenWidth * 0.04,
                                  color: primaryColor,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'public',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.public,
                                          size: screenWidth * 0.04,
                                        ),
                                        SizedBox(width: screenWidth * 0.01),
                                        const Text('Công khai'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'friends',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.group,
                                          size: screenWidth * 0.04,
                                        ),
                                        SizedBox(width: screenWidth * 0.01),
                                        const Text('Bạn bè'),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _visibility = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          if (_selectedAddress != null) ...[
                            SizedBox(height: screenWidth * 0.02),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02,
                                vertical: screenWidth * 0.01,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: primaryColor,
                                    size: screenWidth * 0.04,
                                  ),
                                  SizedBox(width: screenWidth * 0.01),
                                  Expanded(
                                    child: Text(
                                      _selectedAddress!,
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, size: 16),
                                    onPressed: _removeLocation,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          SizedBox(height: screenWidth * 0.02),
                          TextField(
                            controller: _postController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              hintText: 'Bạn đang nghĩ gì?',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: screenWidth * 0.045,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: screenWidth * 0.02,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _isEditing = value.isNotEmpty;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedImage != null)
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenWidth * 0.02,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: screenHeight * 0.35,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child:
                            kIsWeb
                                ? FutureBuilder<Uint8List>(
                                  future: _selectedImage!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                        child: CircularProgressIndicator(
                                          color: primaryColor,
                                        ),
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return const Center(
                                        child: Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                      );
                                    }
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                )
                                : Image.file(
                                  File(_selectedImage!.path),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                      ),
                      Positioned(
                        top: screenWidth * 0.03,
                        right: screenWidth * 0.03,
                        child: GestureDetector(
                          onTap: _removeImage,
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.02),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: screenWidth * 0.05,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: screenWidth * 0.03,
                        left: screenWidth * 0.03,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.02),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: screenWidth * 0.05,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_selectedMusicUrl != null)
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenWidth * 0.02,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenWidth * 0.03,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.music_note,
                          color: primaryColor,
                          size: screenWidth * 0.06,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đang phát nhạc',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.035,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              _selectedMusicUrl!.split('/').last,
                              style: TextStyle(
                                fontSize: screenWidth * 0.03,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: screenWidth * 0.05,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        onPressed: _removeMusic,
                      ),
                    ],
                  ),
                ),
              SizedBox(height: screenWidth * 0.03),
              Divider(
                height: 1,
                thickness: 0.5,
                color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
              ),
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thêm vào bài viết',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.04,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.03),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildOptionButton(
                            icon: Icons.photo_library,
                            label: 'Ảnh/Video',
                            color: Colors.green,
                            onTap: _pickImage,
                            screenWidth: screenWidth,
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          _buildOptionButton(
                            icon: Icons.camera_alt,
                            label: 'Chụp ảnh',
                            color: Colors.blue,
                            onTap: _takePhoto,
                            screenWidth: screenWidth,
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          _buildOptionButton(
                            icon: Icons.location_on,
                            label: 'Vị trí hiện tại',
                            color: Colors.red,
                            onTap: _pickCurrentLocation,
                            screenWidth: screenWidth,
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          _buildOptionButton(
                            icon: Icons.place,
                            label: 'Chọn vị trí',
                            color: Colors.purple,
                            onTap: _showPlacePicker,
                            screenWidth: screenWidth,
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          _buildOptionButton(
                            icon: Icons.auto_awesome,
                            label: 'Caption AI',
                            color: Colors.purple,
                            onTap: _showAiCaptionBottomSheet,
                            screenWidth: screenWidth,
                          ),
                        ],
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

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenWidth * 0.03,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(isDarkMode ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(isDarkMode ? 0.4 : 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: screenWidth * 0.055),
            SizedBox(width: screenWidth * 0.02),
            Text(
              label,
              style: TextStyle(
                color: isDarkMode ? Colors.white : color.withOpacity(0.8),
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
