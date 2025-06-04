// import 'package:first_app/data/repositories/Chat/notification_websocket.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class NotificationService {
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;
//   NotificationService._internal();

//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   Future<void> init() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('app_icon'); // Thay 'app_icon' bằng icon của bạn
//     final InitializationSettings initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid,
//     );
//     await _flutterLocalNotificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         // Xử lý khi nhấn vào thông báo
//         if (response.payload != null) {
//           // Chuyển hướng đến Notification Screen
//           // Sẽ xử lý trong main.dart
//         }
//       },
//     );
//   }

//   Future<void> showNotification(NotificationMessage notification) async {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'notification_channel',
//       'Notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//     );
//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);
//     await _flutterLocalNotificationsPlugin.show(
//       notification.id,
//       notification.title,
//       notification.body,
//       platformChannelSpecifics,
//       payload: 'notification_screen', // Payload để chuyển hướng
//     );
//   }
// }