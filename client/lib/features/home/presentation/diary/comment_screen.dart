import 'dart:io' as io;

import 'package:first_app/data/models/comment.dart';
import 'package:first_app/data/repositories/Comment_repo/comment_repo.dart';
import 'package:first_app/features/home/presentation/ai_caption/bloc_comments/comment_suggestion_bloc.dart';
import 'package:first_app/features/home/presentation/ai_caption/bloc_comments/comment_suggestion_event.dart';
import 'package:first_app/features/home/presentation/ai_caption/bloc_comments/comment_suggestion_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatar;
  final String postContent;
  final String? postImageUrl;

  const CommentScreen({
    Key? key,
    required this.postId,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatar,
    required this.postContent, // Thêm
    this.postImageUrl, // Thêm
  }) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final CommentRepo _commentService = CommentRepo();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _editCommentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;
  bool _isEditing = false;
  String? _editingCommentId;
  List<Comment>? _lastComments;
  bool _showError = false;
  String? _replyingToCommentId;
  XFile? _selectedMedia;
  String? _mediaType;
  bool _showSuggestions = false; // Thêm

  @override
  void initState() {
    super.initState();
    print('CommentScreen: initState - Triggering GenerateCommentSuggestions');
    // Khởi tạo gợi ý bình luận
    context.read<CommentSuggestionBloc>().add(
      GenerateCommentSuggestions(
        postContent: widget.postContent,
        imageUrl: widget.postImageUrl,
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _editCommentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(bool isImage) async {
    final picker = ImagePicker();
    try {
      final XFile? media =
          await (isImage
              ? picker.pickImage(source: ImageSource.gallery)
              : picker.pickVideo(source: ImageSource.gallery));
      if (media != null) {
        setState(() {
          _selectedMedia = media;
          _mediaType = isImage ? 'image' : 'video';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi chọn media: $e')));
    }
  }

  Future<void> _submitComment({String? parentCommentId}) async {
    final content = _commentController.text.trim();
    if (content.isEmpty && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung hoặc chọn media')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _showError = false;
    });

    try {
      print(
        'Submitting comment/reply at ${DateTime.now()} for post: ${widget.postId}, parent: $parentCommentId',
      );
      final tempComment = Comment(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        postId: widget.postId,
        userId: widget.currentUserId,
        userName: widget.currentUserName,
        userAvatar: widget.currentUserAvatar,
        content: content,
        createdAt: DateTime.now(),
        likes: [],
        parentCommentId: parentCommentId,
        mediaUrl: _selectedMedia != null ? 'temp_media' : null,
        mediaType: _mediaType,
      );
      setState(() {
        _lastComments = [...?_lastComments, tempComment];
      });

      String? newCommentId;
      if (parentCommentId != null) {
        final docRef = await _commentService.replyToComment(
          parentCommentId: parentCommentId,
          postId: widget.postId,
          userId: widget.currentUserId,
          userName: widget.currentUserName,
          userAvatar: widget.currentUserAvatar,
          content: content,
          media: _selectedMedia,
          mediaType: _mediaType,
        );
        newCommentId = docRef.id;
      } else {
        final docRef = await _commentService.addComment(
          postId: widget.postId,
          userId: widget.currentUserId,
          userName: widget.currentUserName,
          content: content,
          userAvatar: widget.currentUserAvatar,
          media: _selectedMedia,
          mediaType: _mediaType,
        );
        newCommentId = docRef.id;
      }
      print('Comment/reply submitted successfully with ID: $newCommentId');

      _commentController.clear();
      setState(() {
        _replyingToCommentId = null;
        _selectedMedia = null;
        _mediaType = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error submitting comment: $e');
      setState(() {
        _lastComments =
            _lastComments?.where((c) => !c.id.startsWith('temp_')).toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi gửi bình luận: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _editComment(String commentId, String currentContent) async {
    _editCommentController.text = currentContent;
    setState(() {
      _isEditing = true;
      _editingCommentId = commentId;
    });

    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        return AlertDialog(
          title: const Text('Chỉnh sửa bình luận'),
          content: TextField(
            controller: _editCommentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Nhập nội dung mới...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isEditing = false;
                  _editingCommentId = null;
                });
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newContent = _editCommentController.text.trim();
                if (newContent.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bình luận không thể trống')),
                  );
                  return;
                }

                try {
                  await _commentService.updateComment(
                    commentId: commentId,
                    content: newContent,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chỉnh sửa bình luận thành công'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi chỉnh sửa: $e')),
                  );
                } finally {
                  setState(() {
                    _isEditing = false;
                    _editingCommentId = null;
                  });
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _commentService.deleteComment(commentId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Xóa bình luận thành công'),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Lỗi khi xóa: $e')),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _toggleLikeComment(String commentId) async {
    try {
      await _commentService.toggleLikeComment(commentId, widget.currentUserId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi thích/bỏ thích: $e')));
    }
  }

  void _startReplying(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _commentController.text = '$userName ';
    });
    _commentFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return BlocBuilder<CommentSuggestionBloc, CommentSuggestionState>(
      builder: (context, state) {
        print('CommentScreen: BlocBuilder - State: ${state.runtimeType}');
        if (state is CommentSuggestionLoaded) {
          print('CommentScreen: Suggestions - ${state.suggestions}');
        } else if (state is CommentSuggestionError) {
          print('CommentScreen: Error - ${state.message}');
        }
        return Scaffold(
          backgroundColor: isDarkMode ? Colors.black : Colors.grey[50],
          appBar: AppBar(
            title: const Text(
              'Bình luận',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: isDarkMode ? Colors.black : primaryColor,
            elevation: isDarkMode ? 0 : 1,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder:
                        (context) => Container(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Quy tắc bình luận',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text('Hãy tôn trọng người khác khi bình luận'),
                              Text(
                                'Không sử dụng ngôn từ thô tục hoặc phân biệt',
                              ),
                              Text('Không spam hoặc quảng cáo'),
                            ],
                          ),
                        ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Comment>>(
                  key: ValueKey(widget.postId),
                  stream: _commentService.getComments(widget.postId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      print(
                        'Stream received ${snapshot.data!.length} comments',
                      );
                      _lastComments = snapshot.data;
                      _showError = false;
                    } else if (snapshot.hasError) {
                      print('CommentScreen: Stream error - ${snapshot.error}');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        _lastComments == null) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: primaryColor,
                          strokeWidth: 3,
                        ),
                      );
                    }

                    if (_showError ||
                        (snapshot.hasError && _lastComments == null)) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: screenWidth * 0.15,
                              color: Colors.red[300],
                            ),
                            SizedBox(height: screenWidth * 0.03),
                            Text(
                              'Không thể tải bình luận',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[300],
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.01),
                            Text(
                              'Lỗi: ${snapshot.error ?? "Không xác định"}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.03),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _showError = false;
                                });
                              },
                              child: const Text('Thử lại'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final comments = _lastComments ?? snapshot.data ?? [];
                    if (comments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: screenWidth * 0.15,
                              color:
                                  isDarkMode
                                      ? Colors.grey[700]
                                      : Colors.grey[400],
                            ),
                            SizedBox(height: screenWidth * 0.03),
                            Text(
                              'Chưa có bình luận nào',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w500,
                                color:
                                    isDarkMode
                                        ? Colors.grey[500]
                                        : Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.01),
                            Text(
                              'Hãy là người đầu tiên bình luận!',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color:
                                    isDarkMode
                                        ? Colors.grey[600]
                                        : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final sortedComments = _buildCommentTree(comments);
                    print(
                      'Displaying ${sortedComments.length} sorted comments',
                    );

                    return ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenWidth * 0.02,
                      ),
                      itemCount: sortedComments.length,
                      itemBuilder: (context, index) {
                        final comment = sortedComments[index];
                        final isCurrentUserComment =
                            comment.userId == widget.currentUserId;
                        final isLiked = comment.likes.contains(
                          widget.currentUserId,
                        );
                        final level = _getCommentLevel(comment, comments);

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: screenWidth * 0.03,
                            left: level * screenWidth * 0.08,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border:
                                          isCurrentUserComment
                                              ? Border.all(
                                                color: primaryColor,
                                                width: 2,
                                              )
                                              : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: screenWidth * 0.05,
                                      backgroundImage: NetworkImage(
                                        comment.userAvatar,
                                      ),
                                    ),
                                  ),
                                  if (level > 0)
                                    Positioned(
                                      top: -8,
                                      left: -8,
                                      child: Icon(
                                        Icons.reply,
                                        size: 16,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[500]
                                                : Colors.grey[700],
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        screenWidth * 0.03,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isCurrentUserComment
                                                ? primaryColor.withOpacity(
                                                  isDarkMode ? 0.2 : 0.1,
                                                )
                                                : isDarkMode
                                                ? Colors.grey[800]
                                                : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(16),
                                        border:
                                            isCurrentUserComment
                                                ? Border.all(
                                                  color: primaryColor
                                                      .withOpacity(0.5),
                                                  width: 1.5,
                                                )
                                                : null,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                comment.userName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: screenWidth * 0.035,
                                                  color:
                                                      isCurrentUserComment
                                                          ? primaryColor
                                                          : isDarkMode
                                                          ? Colors.white
                                                          : Colors.black87,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              if (isCurrentUserComment)
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: primaryColor
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Bạn',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: primaryColor,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: screenWidth * 0.01),
                                          if (comment.content.isNotEmpty)
                                            Text(
                                              comment.content,
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.035,
                                                color:
                                                    isDarkMode
                                                        ? Colors.white
                                                        : Colors.black87,
                                              ),
                                            ),
                                          if (comment.mediaUrl != null &&
                                              comment.mediaType == 'image')
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: screenWidth * 0.02,
                                              ),
                                              child: GestureDetector(
                                                onTap: () {
                                                  // Hiển thị ảnh ở chế độ xem toàn màn hình
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (context) => Dialog(
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            child: Image.network(
                                                              comment.mediaUrl!,
                                                              fit:
                                                                  BoxFit
                                                                      .contain,
                                                            ),
                                                          ),
                                                        ),
                                                  );
                                                },
                                                child: Hero(
                                                  tag: comment.mediaUrl!,
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color:
                                                              isDarkMode
                                                                  ? Colors
                                                                      .grey[700]!
                                                                  : Colors
                                                                      .grey[300]!,
                                                          width: 1,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Image.network(
                                                        comment.mediaUrl!,
                                                        width:
                                                            screenWidth * 0.5,
                                                        height:
                                                            screenWidth * 0.5,
                                                        fit: BoxFit.cover,
                                                        loadingBuilder: (
                                                          context,
                                                          child,
                                                          loadingProgress,
                                                        ) {
                                                          if (loadingProgress ==
                                                              null)
                                                            return child;
                                                          return Container(
                                                            width:
                                                                screenWidth *
                                                                0.5,
                                                            height:
                                                                screenWidth *
                                                                0.5,
                                                            color:
                                                                isDarkMode
                                                                    ? Colors
                                                                        .grey[800]
                                                                    : Colors
                                                                        .grey[200],
                                                            child: Center(
                                                              child: CircularProgressIndicator(
                                                                value:
                                                                    loadingProgress.expectedTotalBytes !=
                                                                            null
                                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                                            (loadingProgress.expectedTotalBytes ??
                                                                                1)
                                                                        : null,
                                                                color:
                                                                    primaryColor,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) => Container(
                                                              width:
                                                                  screenWidth *
                                                                  0.5,
                                                              height:
                                                                  screenWidth *
                                                                  0.5,
                                                              color:
                                                                  isDarkMode
                                                                      ? Colors
                                                                          .grey[800]
                                                                      : Colors
                                                                          .grey[200],
                                                              child: Column(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .broken_image,
                                                                    size: 40,
                                                                    color:
                                                                        Colors
                                                                            .red,
                                                                  ),
                                                                  SizedBox(
                                                                    height: 8,
                                                                  ),
                                                                  Text(
                                                                    'Không tải được ảnh',
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (comment.mediaUrl != null &&
                                              comment.mediaType == 'video')
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: screenWidth * 0.02,
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color:
                                                          isDarkMode
                                                              ? Colors
                                                                  .grey[700]!
                                                              : Colors
                                                                  .grey[300]!,
                                                      width: 1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: VideoPlayerWidget(
                                                    videoUrl: comment.mediaUrl!,
                                                    width: screenWidth * 0.5,
                                                    height: screenWidth * 0.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: screenWidth * 0.02,
                                        top: screenWidth * 0.01,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            _formatTimeAgo(comment.createdAt),
                                            style: TextStyle(
                                              color:
                                                  isDarkMode
                                                      ? Colors.grey[500]
                                                      : Colors.grey[600],
                                              fontSize: screenWidth * 0.03,
                                            ),
                                          ),
                                          SizedBox(width: screenWidth * 0.03),
                                          GestureDetector(
                                            onTap:
                                                () => _toggleLikeComment(
                                                  comment.id,
                                                ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isLiked
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color:
                                                      isLiked
                                                          ? Colors.red
                                                          : (isDarkMode
                                                              ? Colors.grey[400]
                                                              : Colors
                                                                  .grey[700]),
                                                  size: screenWidth * 0.04,
                                                ),
                                                SizedBox(
                                                  width: screenWidth * 0.01,
                                                ),
                                                Text(
                                                  comment.likes.length
                                                      .toString(),
                                                  style: TextStyle(
                                                    color:
                                                        isLiked
                                                            ? Colors.red
                                                            : isDarkMode
                                                            ? Colors.grey[400]
                                                            : Colors.grey[700],
                                                    fontSize:
                                                        screenWidth * 0.03,
                                                    fontWeight:
                                                        isLiked
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: screenWidth * 0.03),
                                          GestureDetector(
                                            onTap:
                                                () => _startReplying(
                                                  comment.id,
                                                  comment.userName,
                                                ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.reply,
                                                  size: screenWidth * 0.04,
                                                  color:
                                                      isDarkMode
                                                          ? Colors.grey[400]
                                                          : Colors.grey[700],
                                                ),
                                                SizedBox(
                                                  width: screenWidth * 0.01,
                                                ),
                                                Text(
                                                  'Phản hồi',
                                                  style: TextStyle(
                                                    color:
                                                        isDarkMode
                                                            ? Colors.grey[400]
                                                            : Colors.grey[700],
                                                    fontSize:
                                                        screenWidth * 0.03,
                                                    fontWeight: FontWeight.w500,
                                                  ),
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
                              if (isCurrentUserComment)
                                GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      builder:
                                          (context) => Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                margin: EdgeInsets.only(
                                                  top: 8,
                                                  bottom: 16,
                                                ),
                                                width: 40,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color:
                                                      isDarkMode
                                                          ? Colors.grey[600]
                                                          : Colors.grey[300],
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                ),
                                                title: const Text(
                                                  'Chỉnh sửa bình luận',
                                                ),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _editComment(
                                                    comment.id,
                                                    comment.content,
                                                  );
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                title: const Text(
                                                  'Xóa bình luận',
                                                ),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (
                                                          context,
                                                        ) => AlertDialog(
                                                          title: const Text(
                                                            'Xóa bình luận',
                                                          ),
                                                          content: const Text(
                                                            'Bạn có chắc muốn xóa bình luận này không?',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.pop(
                                                                        context,
                                                                      ),
                                                              child: const Text(
                                                                'Hủy',
                                                              ),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () async {
                                                                Navigator.pop(
                                                                  context,
                                                                );
                                                                await _deleteComment(
                                                                  comment.id,
                                                                );
                                                              },
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                              child: const Text(
                                                                'Xóa',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  );
                                                },
                                              ),
                                              SizedBox(
                                                height: screenWidth * 0.02,
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.more_vert,
                                      color:
                                          isDarkMode
                                              ? Colors.grey[500]
                                              : Colors.grey[600],
                                      size: screenWidth * 0.05,
                                    ),
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
              if (_showSuggestions)
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          top: 6,
                          bottom: 4,
                        ),
                        child: Text(
                          'Gợi ý bình luận:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                            state is CommentSuggestionLoading
                                ? Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        primaryColor,
                                      ),
                                    ),
                                  ),
                                )
                                : state is CommentSuggestionLoaded &&
                                    state.suggestions.isNotEmpty
                                ? ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  itemCount: state.suggestions.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          _commentController.text =
                                              state.suggestions[index];
                                          _commentFocusNode.requestFocus();
                                          setState(() {
                                            _showSuggestions = false;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isDarkMode
                                                    ? Colors.grey[700]
                                                    : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: primaryColor.withOpacity(
                                                0.5,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              state.suggestions[index],
                                              style: TextStyle(
                                                fontSize: 13,
                                                color:
                                                    isDarkMode
                                                        ? Colors.white
                                                        : Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                                : Center(
                                  child: Text(
                                    'Không có gợi ý bình luận',
                                    style: TextStyle(
                                      color:
                                          isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenWidth * 0.03,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, -1),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    if (_replyingToCommentId != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: screenWidth * 0.02),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Đang trả lời bình luận',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _replyingToCommentId = null;
                                    _commentController.clear();
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_selectedMedia != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: screenWidth * 0.02),
                        child: Stack(
                          children: [
                            Container(
                              width: screenWidth * 0.3,
                              height: screenWidth * 0.3,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child:
                                  _mediaType == 'image'
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child:
                                            kIsWeb
                                                ? Image.network(
                                                  _selectedMedia!.path,
                                                  fit: BoxFit.cover,
                                                )
                                                : Image.file(
                                                  io.File(_selectedMedia!.path),
                                                  fit: BoxFit.cover,
                                                ),
                                      )
                                      : Container(
                                        decoration: BoxDecoration(
                                          color:
                                              isDarkMode
                                                  ? Colors.grey[800]
                                                  : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.videocam,
                                          size: 50,
                                          color: primaryColor,
                                        ),
                                      ),
                            ),
                            Positioned(
                              right: -5,
                              top: -5,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedMedia = null;
                                    _mediaType = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          isDarkMode
                                              ? Colors.black
                                              : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryColor, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: screenWidth * 0.05,
                            backgroundImage: NetworkImage(
                              widget.currentUserAvatar,
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[100],
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color:
                                    _commentFocusNode.hasFocus
                                        ? primaryColor
                                        : isDarkMode
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                                width: _commentFocusNode.hasFocus ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _commentController,
                                    focusNode: _commentFocusNode,
                                    maxLines: null,
                                    minLines: 1,
                                    keyboardType: TextInputType.multiline,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          _replyingToCommentId != null
                                              ? 'Viết phản hồi...'
                                              : 'Viết bình luận...',
                                      hintStyle: TextStyle(
                                        color:
                                            isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[500],
                                        fontSize: screenWidth * 0.04,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.04,
                                        vertical: screenWidth * 0.035,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _showSuggestions =
                                            value.isEmpty &&
                                            _selectedMedia == null;
                                      });
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.lightbulb,
                                    color:
                                        _showSuggestions
                                            ? primaryColor
                                            : isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                    size: screenWidth * 0.06,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showSuggestions = !_showSuggestions;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.image,
                                    color: primaryColor.withOpacity(
                                      _selectedMedia != null &&
                                              _mediaType == 'image'
                                          ? 0.5
                                          : 1,
                                    ),
                                    size: screenWidth * 0.06,
                                  ),
                                  onPressed: () => _pickMedia(true),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.videocam,
                                    color: primaryColor.withOpacity(
                                      _selectedMedia != null &&
                                              _mediaType == 'video'
                                          ? 0.5
                                          : 1,
                                    ),
                                    size: screenWidth * 0.06,
                                  ),
                                  onPressed: () => _pickMedia(false),
                                ),
                                SizedBox(width: screenWidth * 0.01),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        GestureDetector(
                          onTap:
                              (_isSubmitting ||
                                      (_commentController.text.trim().isEmpty &&
                                          _selectedMedia == null))
                                  ? null
                                  : () => _submitComment(
                                    parentCommentId: _replyingToCommentId,
                                  ),
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            decoration: BoxDecoration(
                              color:
                                  (_isSubmitting ||
                                          (_commentController.text
                                                  .trim()
                                                  .isEmpty &&
                                              _selectedMedia == null))
                                      ? primaryColor.withOpacity(0.5)
                                      : primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child:
                                _isSubmitting
                                    ? SizedBox(
                                      width: screenWidth * 0.045,
                                      height: screenWidth * 0.045,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                      size: screenWidth * 0.05,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Comment> _buildCommentTree(List<Comment> comments) {
    print('Building comment tree with ${comments.length} comments');
    final Map<String, List<Comment>> commentMap = {};
    final List<Comment> result = [];

    for (var comment in comments) {
      commentMap[comment.id] = commentMap[comment.id] ?? [];
      if (comment.parentCommentId != null) {
        commentMap[comment.parentCommentId!] =
            commentMap[comment.parentCommentId] ?? [];
        commentMap[comment.parentCommentId]!.add(comment);
      }
    }

    void addCommentWithReplies(Comment comment) {
      result.add(comment);
      final replies = commentMap[comment.id] ?? [];
      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (var reply in replies) {
        addCommentWithReplies(reply);
      }
    }

    final rootComments =
        comments.where((c) => c.parentCommentId == null).toList();
    rootComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (var comment in rootComments) {
      addCommentWithReplies(comment);
    }

    print('Comment tree built with ${result.length} comments');
    return result;
  }

  int _getCommentLevel(Comment comment, List<Comment> comments) {
    int level = 0;
    String? currentId = comment.parentCommentId;
    while (currentId != null) {
      final parent = comments.firstWhere(
        (c) => c.id == currentId,
        orElse:
            () => Comment(
              id: '',
              postId: '',
              userId: '',
              userName: '',
              userAvatar: '',
              content: '',
              createdAt: DateTime.now(),
              likes: [],
            ),
      );
      if (parent.id.isEmpty) break;
      level++;
      currentId = parent.parentCommentId;
    }
    return level;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} năm trước';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} tuần trước';
    } else if (difference.inDays > 0) {
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

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final double width;
  final double height;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize()
          .then((_) {
            setState(() {
              _isInitialized = true;
            });
          })
          .catchError((e) {
            print('Error initializing video: $e');
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized
        ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        )
        : SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(child: CircularProgressIndicator()),
        );
  }
}
