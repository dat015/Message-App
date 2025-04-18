import 'dart:io' as io;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_app/data/models/comment.dart';
import 'package:first_app/data/repositories/Comment_repo/comment_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatar;

  const CommentScreen({
    Key? key,
    required this.postId,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatar,
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
      final XFile? media = await (isImage
          ? picker.pickImage(source: ImageSource.gallery)
          : picker.pickVideo(source: ImageSource.gallery));
      if (media != null) {
        setState(() {
          _selectedMedia = media;
          _mediaType = isImage ? 'image' : 'video';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chọn media: $e')),
      );
    }
  }

  Future<void> _submitComment({String? parentCommentId}) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _showError = false;
    });

    try {
      print('Submitting comment/reply at ${DateTime.now()} for post: ${widget.postId}, parent: $parentCommentId');
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
        _lastComments = _lastComments?.where((c) => !c.id.startsWith('temp_')).toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi gửi bình luận: $e')),
        );
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
          children: [
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
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Lỗi khi xóa: $e')),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
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

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Bình luận'),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Comment>>(
              key: ValueKey(widget.postId),
              stream: _commentService.getComments(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  print('Stream received ${snapshot.data!.length} comments');
                  _lastComments = snapshot.data;
                  _showError = false;
                } else if (snapshot.hasError) {
                  print('Stream error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting && _lastComments == null) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 3,
                    ),
                  );
                }

                if (_showError || (snapshot.hasError && _lastComments == null)) {
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
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
                          color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                        ),
                        SizedBox(height: screenWidth * 0.03),
                        Text(
                          'Chưa có bình luận nào',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.01),
                        Text(
                          'Hãy là người đầu tiên bình luận!',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final sortedComments = _buildCommentTree(comments);
                print('Displaying ${sortedComments.length} sorted comments');

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenWidth * 0.02,
                  ),
                  itemCount: sortedComments.length,
                  itemBuilder: (context, index) {
                    final comment = sortedComments[index];
                    final isCurrentUserComment = comment.userId == widget.currentUserId;
                    final isLiked = comment.likes.contains(widget.currentUserId);
                    final level = _getCommentLevel(comment, comments);

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: screenWidth * 0.03,
                        left: level * screenWidth * 0.08,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
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
                              backgroundImage: NetworkImage(comment.userAvatar),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(screenWidth * 0.03),
                                  decoration: BoxDecoration(
                                    color: isCurrentUserComment
                                        ? primaryColor.withOpacity(isDarkMode ? 0.2 : 0.1)
                                        : isDarkMode
                                            ? Colors.grey[800]
                                            : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(16),
                                    border: isCurrentUserComment
                                        ? Border.all(
                                            color: primaryColor.withOpacity(0.3),
                                            width: 1,
                                          )
                                        : null,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.userName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth * 0.035,
                                          color: isCurrentUserComment
                                              ? primaryColor
                                              : isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: screenWidth * 0.01),
                                      if (comment.content.isNotEmpty)
                                        Text(
                                          comment.content,
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.035,
                                            color: isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      if (comment.mediaUrl != null && comment.mediaType == 'image')
                                        Padding(
                                          padding: EdgeInsets.only(top: screenWidth * 0.02),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              comment.mediaUrl!,
                                              width: screenWidth * 0.5,
                                              height: screenWidth * 0.5,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                            (loadingProgress.expectedTotalBytes ?? 1)
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                                            ),
                                          ),
                                        ),
                                      if (comment.mediaUrl != null && comment.mediaType == 'video')
                                        Padding(
                                          padding: EdgeInsets.only(top: screenWidth * 0.02),
                                          child: VideoPlayerWidget(
                                            videoUrl: comment.mediaUrl!,
                                            width: screenWidth * 0.5,
                                            height: screenWidth * 0.5,
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
                                          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                                          fontSize: screenWidth * 0.03,
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.03),
                                      GestureDetector(
                                        onTap: () => _toggleLikeComment(comment.id),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isLiked ? Icons.favorite : Icons.favorite_border,
                                              color: isLiked
                                                  ? Colors.red
                                                  : (isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                                              size: screenWidth * 0.04,
                                            ),
                                            SizedBox(width: screenWidth * 0.01),
                                            Text(
                                              comment.likes.length.toString(),
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                                fontSize: screenWidth * 0.03,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.03),
                                      GestureDetector(
                                        onTap: () => _startReplying(comment.id, comment.userName),
                                        child: Text(
                                          'Phản hồi',
                                          style: TextStyle(
                                            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                            fontSize: screenWidth * 0.03,
                                            fontWeight: FontWeight.w500,
                                          ),
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
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  builder: (context) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.edit, color: Colors.blue),
                                        title: const Text('Chỉnh sửa'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _editComment(comment.id, comment.content);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.delete, color: Colors.red),
                                        title: const Text('Xóa'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Xóa bình luận'),
                                              content: const Text('Bạn có chắc muốn xóa bình luận này?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Hủy'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    Navigator.pop(context);
                                                    await _deleteComment(comment.id);
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                  ),
                                                  child: const Text('Xóa'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      SizedBox(height: screenWidth * 0.02),
                                    ],
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.more_vert,
                                color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                                size: screenWidth * 0.05,
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                if (_selectedMedia != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: screenWidth * 0.02),
                    child: Stack(
                      children: [
                        Container(
                          width: screenWidth * 0.3,
                          height: screenWidth * 0.3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _mediaType == 'image'
                              ? kIsWeb
                                  ? Image.network(_selectedMedia!.path)
                                  : Image.file(io.File(_selectedMedia!.path), fit: BoxFit.cover)
                              : const Icon(Icons.videocam, size: 50), // Placeholder for video
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMedia = null;
                                _mediaType = null;
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
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
                        backgroundImage: NetworkImage(widget.currentUserAvatar),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                            width: 1,
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
                                textCapitalization: TextCapitalization.sentences,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  hintText: _replyingToCommentId != null
                                      ? 'Viết phản hồi...'
                                      : 'Viết bình luận...',
                                  hintStyle: TextStyle(
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                                    fontSize: screenWidth * 0.04,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                    vertical: screenWidth * 0.035,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.image,
                                color: primaryColor,
                                size: screenWidth * 0.06,
                              ),
                              onPressed: () => _pickMedia(true),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.videocam,
                                color: primaryColor,
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
                      onTap: _isSubmitting
                          ? null
                          : () => _submitComment(parentCommentId: _replyingToCommentId),
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: screenWidth * 0.045,
                                height: screenWidth * 0.045,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

    // Thêm bình luận gốc và phản hồi theo thứ tự
    void addCommentWithReplies(Comment comment) {
      result.add(comment);
      final replies = commentMap[comment.id] ?? [];
      // Sắp xếp phản hồi theo createdAt tăng dần
      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (var reply in replies) {
        addCommentWithReplies(reply);
      }
    }

    // Lấy bình luận gốc, sắp xếp theo createdAt giảm dần
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
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      }).catchError((e) {
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
                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
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
