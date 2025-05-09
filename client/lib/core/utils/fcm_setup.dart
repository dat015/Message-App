import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Thông báo nền: ${message.notification?.title}');
}

Future<void> setupFCM(String? userId) async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (userId != null) {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Thông báo foreground: ${message.notification?.title}');
  });
}