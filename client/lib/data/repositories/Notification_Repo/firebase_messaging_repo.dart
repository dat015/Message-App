import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_app/features/routes/routes.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initNotifications(String userId) async {
    try {
      await _messaging.requestPermission();

      final fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        print('FCM Token: $fcmToken');
        await _firestore.collection('users').doc(userId).set(
          {'fcmToken': fcmToken},
          SetOptions(merge: true),
        );
        print('FCM Token saved for user: $userId');
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received foreground notification: ${message.notification?.title}');
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Notification clicked: ${message.data}');
        if (message.data['postId'] != null) {
          // MyApp.navigatorKey.currentState?.pushNamed(
          //   AppRoutes.postDetail, // Giả định bạn có route này
          //   arguments: message.data['postId'],
          // );
        }
      });

      // Xử lý thông báo khi ứng dụng khởi động từ trạng thái terminated
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null && initialMessage.data['postId'] != null) {
        // MyApp.navigatorKey.currentState?.pushNamed(
        //   AppRoutes.postDetail,
        //   arguments: initialMessage.data['postId'],
        // );
      }

      // Xử lý refresh token
      _messaging.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        await _firestore.collection('users').doc(userId).set(
          {'fcmToken': newToken},
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }
}