import 'package:first_app/data/models/post.dart';
import 'package:first_app/data/repositories/Post_repo/post_repo.dart';
import 'package:flutter/material.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;
  final String currentUserId;
  final String currentUserName;
  final String currentUserAvatar;

  const EditPostScreen({
    Key? key,
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatar,
  }) : super(key: key);

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final PostRepo _postRepo = PostRepo();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.post.content ?? '';
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _updatePost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nội dung không được để trống')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _postRepo.updatePost(
        widget.post.id.toString(),
        _contentController.text.trim(),
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật bài viết thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa bài viết'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updatePost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Lưu',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(widget.currentUserAvatar),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.currentUserName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Hôm nay bạn thế nào?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade700),
                ),
              ),
            ),
            if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Image.network(
                  widget.post.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}