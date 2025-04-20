import 'package:first_app/data/models/post.dart';
import 'package:first_app/data/models/story.dart';
import 'package:first_app/features/home/presentation/diary/comment_screen.dart';
import 'package:first_app/features/home/presentation/diary/create_post.dart';
import 'package:first_app/features/home/presentation/diary/edit_post_screen.dart';
import 'package:first_app/features/home/presentation/story/create_story_screen.dart';
import 'package:first_app/features/home/presentation/story/story_screen.dart';
import 'package:first_app/features/home/presentation/friends/qr_scanner.dart';
import 'package:first_app/features/home/presentation/users_profile/other_us_profile.dart';
import 'package:first_app/features/home/presentation/friends/bloc/friends_bloc.dart';
import 'package:flutter/material.dart';

// Class tiện ích để quản lý điều hướng
class NavigationHelper {
  // Singleton instance để tái sử dụng
  static final NavigationHelper _instance = NavigationHelper._internal();
  factory NavigationHelper() => _instance;
  NavigationHelper._internal();

  // Điều hướng đến một màn hình cụ thể với widget
  Future<T?> pushScreen<T>(
    BuildContext context,
    Widget screen, {
    bool replace = false,
  }) async {
    try {
      if (replace) {
        return await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      } else {
        return await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      }
    } catch (e) {
      debugPrint('Push screen error: $e');
      _showErrorSnackBar(context, 'Lỗi điều hướng: $e');
      return null;
    }
  }

  // Quay lại màn hình trước đó
  void pop<T>(BuildContext context, [T? result]) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
    } else {
      debugPrint('Cannot pop: No previous screen');
      _showErrorSnackBar(context, 'Không thể quay lại');
    }
  }

  // Điều hướng đến CreatePostScreen
  Future<void> goToCreatePost(
    BuildContext context,
    int currentUserId,
    String currentUserName,
    String currentUserAvatar, {
    bool replace = false,
  }) async {
    await pushScreen(
      context,
      CreatePostScreen(
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        currentUserAvatar: currentUserAvatar,
      ),
      replace: replace,
    );
  }

  // Điều hướng đến CreateStoryScreen
  Future<void> goToCreateStory(
    BuildContext context,
    String currentUserId,
    String currentUserName,
    String currentUserAvatar, {
    bool replace = false,
  }) async {
    await pushScreen(
      context,
      CreateStoryScreen(
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        currentUserAvatar: currentUserAvatar,
      ),
      replace: replace,
    );
  }

  // Điều hướng đến StoryScreen
  Future<void> goToStory(
    BuildContext context,
    String currentUserId,
    List<Story> stories, {
    bool replace = false,
  }) async {
    await pushScreen(
      context,
      StoryScreen(
        currentUserId: currentUserId,
        stories: stories,
      ),
      replace: replace,
    );
  }

  // Điều hướng đến EditPostScreen
  Future<void> goToEditPost(
    BuildContext context,
    Post post,
    String currentUserId,
    String currentUserName,
    String currentUserAvatar, {
    bool replace = false,
  }) async {
    await pushScreen(
      context,
      EditPostScreen(
        post: post,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        currentUserAvatar: currentUserAvatar,
      ),
      replace: replace,
    );
  }

  // Điều hướng đến CommentScreen
  Future<void> goToComment(
    BuildContext context,
    String postId,
    String currentUserId,
    String currentUserName,
    String currentUserAvatar,
    String postContent, {
    bool replace = false,
  }) async {
    await pushScreen(
      context,
      CommentScreen(
        postId: postId,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        currentUserAvatar: currentUserAvatar, postContent: postContent,
      ),
      replace: replace,
    );
  }

  Future<void> goToProfile(
    BuildContext context,
    int viewerId,
    int targetUserId, {
    bool replace = false,
  }) async {
    await pushScreen(
      context,
      OtherProfilePage(
        viewerId: viewerId,
        targetUserId: targetUserId,
      ),
      replace: replace,
    );
  }

  // Điều hướng đến NewQrScannerScreen
  Future<void> goToQrScanner(
    BuildContext context,
    FriendsBloc friendsBloc, {
    bool replace = false,
  }) async {
    await pushScreen(
      context,
      NewQrScannerScreen(friendsBloc: friendsBloc),
      replace: replace,
    );
  }

  // Hàm hiển thị SnackBar khi có lỗi
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}