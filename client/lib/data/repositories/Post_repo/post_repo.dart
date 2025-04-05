import 'dart:io' as io if (dart.library.html) 'dart:html';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:first_app/data/models/post.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class PostRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createPost({
    required String currentUserId,
    required String content,
    required String authorName,
    XFile? image,
    String? musicUrl,
    List<String>? taggedFriends,
  }) async {
    try {
      if (currentUserId.isEmpty) {
        throw Exception('ID người dùng không hợp lệ');
      }

      String? imageUrl;
      if (image != null) {
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final originalFileName = path.basename(image.path);
          final fileExtension = path.extension(originalFileName).toLowerCase();
          final fileName = 'image_${timestamp}${fileExtension}';

          final filePath = 'posts/$currentUserId/$fileName';

          if (kIsWeb) {
            final bytes = await image.readAsBytes();
            await _supabase.storage
                .from('media')
                .uploadBinary(
                  filePath,
                  bytes,
                  fileOptions: const FileOptions(
                    cacheControl: '3600',
                    upsert: false,
                  ),
                );
          } else {
            final file = io.File(image.path);
            await _supabase.storage
                .from('media')
                .upload(
                  filePath,
                  file,
                  fileOptions: const FileOptions(
                    cacheControl: '3600',
                    upsert: false,
                  ),
                );
          }

          imageUrl = _supabase.storage.from('media').getPublicUrl(filePath);

          print('Upload success, image URL: $imageUrl');
        } catch (e) {
          print('Error uploading image: $e');
          throw Exception('Không thể tải ảnh lên: $e');
        }
      }

      final post = Post(
        id: '',
        content: content,
        imageUrl: imageUrl,
        musicUrl: musicUrl,
        createdAt: DateTime.now(),
        authorId: currentUserId,
        authorName: authorName,
        taggedFriends: taggedFriends ?? [],
      );

      await _firestore.collection('posts').add(post.toMap());
      print('Post created successfully');
    } catch (e) {
      print('Error in createPost: $e');
      throw Exception('Lỗi khi tạo bài viết: $e');
    }
  }

  Future<List<Post>> getPosts() async {
    try {
      final snapshot =
          await _firestore
              .collection('posts')
              .orderBy('createdAt', descending: true)
              .get();
      return snapshot.docs
          .map((doc) => Post.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy bài viết: $e');
    }
  }

  Future<List<Post>> getPostsByUserId(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('posts')
              .where('authorId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();
      return snapshot.docs
          .map((doc) => Post.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy bài viết: $e');
    }
  }
}
