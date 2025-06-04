import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_app/data/models/comment.dart';
import 'package:first_app/data/repositories/Notification_Repo/noti_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io' as io if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart' show kIsWeb;

class CommentRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotiRepo _notiRepo = NotiRepo();

  Future<DocumentReference> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String userAvatar,
    required String content,
    XFile? media,
    String? mediaType,
  }) async {
    try {
      print('Adding comment for post: $postId, user: $userId, content: $content');
      String? mediaUrl;
      if (media != null && mediaType != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final originalFileName = path.basename(media.path);
        final fileExtension = path.extension(originalFileName).toLowerCase();
        final fileName = '${mediaType}_${timestamp}${fileExtension}';
        final filePath = 'comments/$userId/$fileName';

        if (kIsWeb) {
          final bytes = await media.readAsBytes();
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
          final file = io.File(media.path);
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

        mediaUrl = _supabase.storage.from('media').getPublicUrl(filePath);
        print('Media uploaded successfully: $mediaUrl');
      }

      final docRef = await _firestore.collection('comments').add({
        'postId': postId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
        'parentCommentId': null,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
      });
      print('Comment added successfully with ID: ${docRef.id}');

      // Lấy postAuthorId từ posts
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) {
        print('Post not found: $postId');
        throw Exception('Bài viết không tồn tại');
      }
      final postAuthorId = postDoc.data()!['authorId'] as String;
      print('Post authorId: $postAuthorId');

      // Tạo thông báo nếu người bình luận khác tác giả bài viết
      if (userId != postAuthorId) {
        try {
          await _notiRepo.createCommentNotification(
            postId: postId,
            postAuthorId: postAuthorId,
            commenterId: userId,
            commenterName: userName,
            commentContent: content,
          );
          print('Notification created for comment on post: $postId');
        } catch (e) {
          print('Error creating comment notification: $e');
        }
      }

      return docRef;
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Lỗi khi thêm bình luận: $e');
    }
  }

  Future<DocumentReference> replyToComment({
  required String parentCommentId,
  required String postId,
  required String userId,
  required String userName,
  required String userAvatar,
  required String content,
  XFile? media,
  String? mediaType,
}) async {
  try {
    print('Adding reply to comment: $parentCommentId, post: $postId, content: $content');
    String? mediaUrl;
    if (media != null && mediaType != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalFileName = path.basename(media.path);
      final fileExtension = path.extension(originalFileName).toLowerCase();
      final fileName = '${mediaType}_${timestamp}${fileExtension}';
      final filePath = 'comments/$userId/$fileName';

      if (kIsWeb) {
        final bytes = await media.readAsBytes();
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
        final file = io.File(media.path);
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

      mediaUrl = _supabase.storage.from('media').getPublicUrl(filePath);
      print('Media uploaded successfully: $mediaUrl');
    }

    DocumentReference? docRef; // Khai báo nullable để tránh lỗi chưa gán
    const maxRetries = 3;
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        docRef = await _firestore.collection('comments').add({
          'postId': postId,
          'userId': userId,
          'userName': userName,
          'userAvatar': userAvatar,
          'content': content,
          'createdAt': FieldValue.serverTimestamp(),
          'likes': [],
          'parentCommentId': parentCommentId,
          'mediaUrl': mediaUrl,
          'mediaType': mediaType,
        });
        print('Reply added successfully with ID: ${docRef.id}');
        break;
      } catch (e) {
        print('Error adding reply (attempt $attempt): $e');
        if (attempt == maxRetries) throw Exception('Lỗi khi phản hồi bình luận: $e');
        await Future.delayed(Duration(seconds: attempt));
      }
    }

    if (docRef == null) {
      throw Exception('Không thể thêm phản hồi sau $maxRetries lần thử');
    }

    // Lấy commentAuthorId từ bình luận gốc
    final parentCommentDoc = await _firestore.collection('comments').doc(parentCommentId).get();
    if (!parentCommentDoc.exists) {
      print('Parent comment not found: $parentCommentId');
      throw Exception('Bình luận gốc không tồn tại');
    }
    final commentAuthorId = parentCommentDoc.data()!['userId'] as String;
    print('Comment authorId: $commentAuthorId');

    // Tạo thông báo cho tác giả bình luận gốc nếu khác người phản hồi
    if (userId != commentAuthorId) {
      try {
        await _notiRepo.createReplyNotification(
          postId: postId,
          commentAuthorId: commentAuthorId,
          replierId: userId,
          replierName: userName,
          replyContent: content,
        );
        print('Notification created for reply to comment: $parentCommentId');
      } catch (e) {
        print('Error creating reply notification: $e');
      }
    }

    // Lấy postAuthorId từ posts
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    if (!postDoc.exists) {
      print('Post not found: $postId');
      throw Exception('Bài viết không tồn tại');
    }
    final postAuthorId = postDoc.data()!['authorId'] as String;
    print('Post authorId: $postAuthorId');

    // Tạo thông báo nếu người phản hồi khác tác giả bài viết
    if (userId != postAuthorId) {
      try {
        await _notiRepo.createCommentNotification(
          postId: postId,
          postAuthorId: postAuthorId,
          commenterId: userId,
          commenterName: userName,
          commentContent: content,
        );
        print('Notification created for reply on post: $postId');
      } catch (e) {
        print('Error creating comment notification: $e');
      }
    }

    return docRef;
  } catch (e) {
    print('Error adding reply: $e');
    throw Exception('Lỗi khi phản hồi bình luận: $e');
  }
}

  Stream<List<Comment>> getComments(String postId) {
    try {
      print('Fetching comments for post: $postId');
      return _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) {
            print('Received ${snapshot.docs.length} comments from Firestore');
            return snapshot.docs
                .map((doc) => Comment.fromMap(doc.id, doc.data()))
                .toList();
          });
    } catch (e) {
      print('Error in getComments: $e');
      if (e.toString().contains('requires an index')) {
        print('Index required for comments query. Please create index in Firestore.');
        return Stream.value([]);
      }
      rethrow;
    }
  }

  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      print('Updating comment: $commentId');
      await _firestore.collection('comments').doc(commentId).update({
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Comment updated successfully');
    } catch (e) {
      print('Error updating comment: $e');
      throw Exception('Lỗi khi chỉnh sửa bình luận: $e');
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      print('Deleting comment: $commentId');
      final commentDoc = await _firestore.collection('comments').doc(commentId).get();
      if (commentDoc.exists && commentDoc.data()!['mediaUrl'] != null) {
        final mediaUrl = commentDoc.data()!['mediaUrl'];
        final filePath = mediaUrl.split('media/').last;
        await _supabase.storage.from('media').remove([filePath]);
        print('Media deleted from Supabase: $filePath');
      }

      final repliesSnapshot = await _firestore
          .collection('comments')
          .where('parentCommentId', isEqualTo: commentId)
          .get();
      for (var doc in repliesSnapshot.docs) {
        if (doc.data()['mediaUrl'] != null) {
          final mediaUrl = doc.data()['mediaUrl'];
          final filePath = mediaUrl.split('media/').last;
          await _supabase.storage.from('media').remove([filePath]);
        }
        await doc.reference.delete();
      }

      await _firestore.collection('comments').doc(commentId).delete();
      print('Comment deleted successfully');
    } catch (e) {
      print('Error deleting comment: $e');
      throw Exception('Lỗi khi xóa bình luận: $e');
    }
  }

  Future<void> toggleLikeComment(String commentId, String userId) async {
    try {
      print('Toggling like for comment: $commentId, user: $userId');
      final commentRef = _firestore.collection('comments').doc(commentId);
      final commentDoc = await commentRef.get();

      if (!commentDoc.exists) {
        throw Exception('Bình luận không tồn tại');
      }

      final commentData = commentDoc.data()!;
      final List<String> updatedLikes = List.from(commentData['likes'] ?? []);

      if (updatedLikes.contains(userId)) {
        updatedLikes.remove(userId);
      } else {
        updatedLikes.add(userId);
      }

      await commentRef.update({'likes': updatedLikes});
      print('Toggled like successfully');
    } catch (e) {
      print('Error toggling like: $e');
      throw Exception('Lỗi khi thích/bỏ thích bình luận: $e');
    }
  }
}