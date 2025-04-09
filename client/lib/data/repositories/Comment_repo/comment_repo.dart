import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_app/data/models/comment.dart';

class CommentRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String userAvatar,
    required String content,
  }) async {
    await _firestore.collection('comments').add({
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Comment>> getComments(String postId) {
    try {
      return _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => Comment.fromMap(doc.id, doc.data()))
                .toList();
          });
    } catch (e) {
      if (e.toString().contains('requires an index')) {
        return Stream.value([]);
      }
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();
    } catch (e) {
      throw Exception('Lỗi khi xóa bình luận: $e');
    }
  }
}
