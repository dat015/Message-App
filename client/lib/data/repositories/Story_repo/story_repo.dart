import 'dart:io' as io if (dart.library.html) 'dart:html';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_app/data/repositories/Friends_repo/friends_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:first_app/data/models/story.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;

class StoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
final FriendsRepo _friendRepo = FriendsRepo();
  Future<String> createStory({
    required String authorId,
    required String authorName,
    required String authorAvatar,
    XFile? imageFile,
    XFile? videoFile,
    String? musicUrl,
    int? musicStartTime,
    int? musicDuration,
    Duration duration = const Duration(hours: 24),
    String visibility = 'public',
  }) async {
    try {
      String? imageUrl;
      String? videoUrl;

      // Upload media lên Supabase
      if (imageFile != null) {
        imageUrl = await _uploadMedia(
          file: imageFile,
          userId: authorId,
          type: 'image',
        );
      } else if (videoFile != null) {
        videoUrl = await _uploadMedia(
          file: videoFile,
          userId: authorId,
          type: 'video',
        );
      } else {
        throw Exception('Cần cung cấp ảnh hoặc video');
      }

      // Tạo story trong Firestore
      final now = DateTime.now();
      final expiresAt = now.add(duration);
      final story = Story(
        id: '',
        authorId: authorId,
        authorName: authorName,
        authorAvatar: authorAvatar,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        musicUrl: musicUrl,
        musicStartTime: musicStartTime,
        musicDuration: musicDuration,
        createdAt: now,
        expiresAt: expiresAt,
        viewers: [],
        reactions: {},
        visibility: visibility,
      );

      final docRef = await _firestore.collection('stories').add(story.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating story: $e');
      throw Exception('Lỗi khi tạo story: $e');
    }
  }

  // Phương thức uploadMedia không thay đổi
  Future<String> _uploadMedia({
    required XFile file,
    required String userId,
    required String type,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalFileName = path.basename(file.path);
      final fileExtension = path.extension(originalFileName).toLowerCase();
      final fileName = '${type}_${timestamp}$fileExtension';
      final filePath = 'stories/$userId/$fileName';

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
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
        final io.File ioFile = io.File(file.path);
        await _supabase.storage
            .from('media')
            .upload(
              filePath,
              ioFile,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );
      }

      return _supabase.storage.from('media').getPublicUrl(filePath);
    } catch (e) {
      print('Error uploading $type: $e');
      throw Exception('Không thể tải $type lên: $e');
    }
  }

  Future<List<Object>> _getFriends(String userId) async {
    try {
      return await _friendRepo.getFriends(int.parse(userId));
    } catch (e) {
      print('Error fetching friends: $e');
      return [];
    }
  }

  // Lấy tất cả story
  Stream<List<Story>> getAllStories(String currentUserId) {
    return _firestore
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
          // Lấy danh sách bạn bè
          final friends = await _getFriends(currentUserId);
          final friendIds = friends.map((friend) => friend..toString()).toList();

          final stories = snapshot.docs.map((doc) => Story.fromMap(doc.id, doc.data())).toList();

          // Lọc story dựa trên visibility
          final filteredStories = stories.where((story) {
            if (story.visibility == 'public') {
              return true; // Story công khai
            } else if (story.visibility == 'friends') {
              // Chỉ bạn bè hoặc chính người đăng mới thấy
              return friendIds.contains(story.authorId) || story.authorId == currentUserId;
            }
            return false;
          }).toList();

          // Sắp xếp để ưu tiên story của người dùng hiện tại
          filteredStories.sort((a, b) {
            if (a.authorId == currentUserId && b.authorId != currentUserId) return -1;
            if (a.authorId != currentUserId && b.authorId == currentUserId) return 1;
            return 0;
          });

          return filteredStories;
        });
  }

  // Lấy danh sách story từ bạn bè
  Stream<List<Story>> getFriendsStories(String currentUserId) {
    return _firestore
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt', descending: false)
        .snapshots()
        .map((snapshot) {
          final stories =
              snapshot.docs.map((doc) {
                final story = Story.fromMap(doc.id, doc.data());
                print(
                  'Friend story: ${story.id}, expiresAt: ${story.expiresAt}',
                ); // Debug
                return story;
              }).toList();
          print('Friend stories: ${stories.length}'); // Debug
          return stories;
        });
  }

  Future<Map<String, dynamic>> getUserInfo(String userId) async {
  try {
    final query = await _firestore
        .collection('stories')
        .where('authorId', isEqualTo: userId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      return {
        'name': data['authorName'] ?? 'Người dùng',
        'avatar': data['authorAvatar'] ?? '',
      };
    } else {
      return {'name': 'Người dùng', 'avatar': ''};
    }
  } catch (e) {
    print('Error fetching user info from stories: $e');
    return {'name': 'Người dùng', 'avatar': ''};
  }
}


  // Đánh dấu story đã xem
  Future<void> markStoryAsViewed(String storyId, String userId) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'viewers': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('Error marking story as viewed: $e');
      throw Exception('Lỗi khi đánh dấu story đã xem: $e');
    }
  }

  // Thêm hoặc cập nhật cảm xúc
  Future<void> addReaction(
    String storyId,
    String userId,
    String reaction,
  ) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'reactions.$userId': reaction,
      });
    } catch (e) {
      print('Error adding reaction: $e');
      throw Exception('Lỗi khi thêm cảm xúc: $e');
    }
  }

  // Xóa cảm xúc
  Future<void> removeReaction(String storyId, String userId) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'reactions.$userId': FieldValue.delete(),
      });
    } catch (e) {
      print('Error removing reaction: $e');
      throw Exception('Lỗi khi xóa cảm xúc: $e');
    }
  }

  // Xóa story đã hết hạn
  Future<void> deleteExpiredStories() async {
    try {
      final expiredStories =
          await _firestore
              .collection('stories')
              .where('expiresAt', isLessThan: Timestamp.now())
              .get();

      for (final doc in expiredStories.docs) {
        await doc.reference.delete();
      }
      print('Deleted ${expiredStories.docs.length} expired stories'); // Debug
    } catch (e) {
      print('Error deleting expired stories: $e');
    }
  }
}
