// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:first_app/PlatformClient/config.dart';
// import 'package:http/http.dart' as http;

// class NotiRepo {
//   String get baseUrl => '${Config.baseUrl}api/friends';
//   final FirebaseFirestore _firestore;

//   NotiRepo({
//     FirebaseFirestore? firestore,
//   }) : _firestore = firestore ?? FirebaseFirestore.instance;

//   // Tạo thông báo "thích" trong Firestore
//   Future<void> createLikeNotification({
//     required String postId,
//     required String postAuthorId,
//     required String likerId,
//     required String likerName,
//   }) async {
//     try {
//       print('Bắt đầu tạo thông báo "thích" trong Firestore...');
//       print('PostId: $postId, PostAuthorId: $postAuthorId, LikerId: $likerId, LikerName: $likerName');

//       // Tạo ID duy nhất cho thông báo
//       final notificationId = _firestore.collection('notifications').doc().id;

//       // Dữ liệu thông báo
//       final notificationData = {
//         'id': notificationId,
//         'type': 'like',
//         'postId': postId,
//         'postAuthorId': postAuthorId,
//         'likerId': likerId,
//         'likerName': likerName,
//         'createdAt': FieldValue.serverTimestamp(),
//         'isRead': false,
//       };

//       // Lưu thông báo vào Firestore
//       await _firestore
//           .collection('notifications')
//           .doc(notificationId)
//           .set(notificationData);
//       print('Thông báo "thích" đã được lưu vào Firestore: $notificationId');

//       // Gửi thông báo đẩy qua FCM
//       await _sendPushNotification(
//         userId: postAuthorId,
//         title: 'Thích mới',
//         body: '$likerName đã thích bài viết của bạn.',
//       );
//       print('Yêu cầu gửi thông báo đẩy đã được gửi đến backend.');
//     } catch (e) {
//       print('Lỗi khi tạo thông báo "thích": $e');
//       rethrow;
//     }
//   }

//   // Gửi yêu cầu đến backend để gửi thông báo đẩy qua FCM
//   Future<void> _sendPushNotification({
//     required String userId,
//     required String title,
//     required String body,
//   }) async {
//     try {
//       print('Gửi yêu cầu gửi thông báo đẩy đến backend...');
//       print('UserId: $userId, Title: $title, Body: $body');

//       final response = await http.post(
//         Uri.parse('$baseUrl/api/notification/send'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'userId': userId,
//           'title': title,
//           'body': body,
//         }),
//       );

//       if (response.statusCode == 200) {
//         print('Gửi thông báo đẩy thành công: ${response.body}');
//       } else {
//         print('Gửi thông báo đẩy thất bại: StatusCode: ${response.statusCode}, Body: ${response.body}');
//         throw Exception('Gửi thông báo đẩy thất bại: ${response.body}');
//       }
//     } catch (e) {
//       print('Lỗi khi gửi thông báo đẩy: $e');
//       rethrow;
//     }
//   }

//   Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
//     try {
//       print('Bắt đầu lấy danh sách thông báo cho userId: $userId');
//       return _firestore
//           .collection('notifications')
//           .where('postAuthorId', isEqualTo: userId)
//           .orderBy('createdAt', descending: true)
//           .snapshots()
//           .map((snapshot) {
//             final notifications = snapshot.docs.map((doc) {
//               final data = doc.data();
//               print('Thông báo tìm thấy: ${data['id']} - Type: ${data['type']}, IsRead: ${data['isRead']}');
//               return data;
//             }).toList();
//             print('Tổng số thông báo tìm thấy: ${notifications.length}');
//             return notifications;
//           });
//     } catch (e) {
//       print('Lỗi khi lấy danh sách thông báo: $e');
//       rethrow;
//     }
//   }

//   // Đánh dấu thông báo là đã đọc
//   Future<void> markAsRead(String notificationId) async {
//     try {
//       print('Bắt đầu đánh dấu thông báo là đã đọc: $notificationId');
//       await _firestore
//           .collection('notifications')
//           .doc(notificationId)
//           .update({'isRead': true});
//       print('Đánh dấu thông báo là đã đọc thành công: $notificationId');
//     } catch (e) {
//       print('Lỗi khi đánh dấu thông báo là đã đọc: $e');
//       rethrow;
//     }
//   }
// }