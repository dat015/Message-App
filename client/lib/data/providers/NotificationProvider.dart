// import 'dart:convert';
// import 'package:first_app/data/repositories/Chat/notification_websocket.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class NotificationProvider with ChangeNotifier {
//   List<NotificationMessage> _notifications = [];
//   List<NotificationMessage> get notifications => _notifications;

//   NotificationProvider() {
//     _loadNotifications();
//   }

//   Future<void> _loadNotifications() async {
//     final prefs = await SharedPreferences.getInstance();
//     final notificationJson = prefs.getString('notifications');
//     if (notificationJson != null) {
//       final List<dynamic> decoded = jsonDecode(notificationJson);
//       _notifications = decoded.map((json) => NotificationMessage.fromJson(json)).toList();
//       notifyListeners();
//     }
//   }

//   Future<void> addNotification(NotificationMessage notification) async {
//     _notifications.insert(0, notification); // Thêm vào đầu danh sách
//     notifyListeners();

//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('notifications', jsonEncode(_notifications.map((n) => n.toJson()).toList()));
//   }

//   Future<void> clearNotifications() async {
//     _notifications.clear();
//     notifyListeners();

//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('notifications');
//   }
// }