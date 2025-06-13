// import 'dart:async';
// import 'dart:convert';
// import 'package:web_socket_channel/web_socket_channel.dart';

// class NotificationMessage {
//   final int senderId;
//   final String title;
//   final String body;
//   final String type;
//   final int id;

//   NotificationMessage({
//     required this.senderId,
//     required this.title,
//     required this.body,
//     required this.type,
//     required this.id,
//   });

//   factory NotificationMessage.fromJson(Map<String, dynamic> json) {
//     return NotificationMessage(
//       senderId: json['SenderId'] as int,
//       title: json['Title'] as String,
//       body: json['Body'] as String,
//       type: json['Type'] as String,
//       id: json['Id'] as int,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'SenderId': senderId,
//       'Title': title,
//       'Body': body,
//       'Type': type,
//       'Id': id,
//     };
//   }
// }

// class NotificationWebSocketService {
//   static final NotificationWebSocketService _instance = NotificationWebSocketService._internal();

//   factory NotificationWebSocketService() {
//     return _instance;
//   }

//   NotificationWebSocketService._internal();

//   late String _url;
//   late Function(NotificationMessage) _onNotificationReceived;

//   bool _isConnected = false;
//   bool get isConnected => _isConnected;

//   WebSocketChannel? _channel;
//   final _notificationController = StreamController<NotificationMessage>.broadcast();
//   Stream<NotificationMessage> get notifications => _notificationController.stream;

//   void init({
//     required String url,
//     required Function(NotificationMessage) onNotificationReceived,
//   }) {
//     _url = url;
//     _onNotificationReceived = onNotificationReceived;
//   }

//   void connect(int userId) {
//     if (_isConnected) {
//       print("Notification WebSocket already connected to $_url");
//       return;
//     }

//     try {
//       print("Attempting to connect to Notification WebSocket at: $_url");
//       _channel = WebSocketChannel.connect(Uri.parse('$_url?userId=$userId'));
//       _isConnected = true;
//       print("Notification WebSocket connection established");

//       // Gửi bootup message ngay sau khi kết nối
//       sendBootupMessage(userId);

//       _channel!.stream.listen(
//         (data) {
//           try {
//             if (data == "ping") {
//               print("Received ping message, ignoring...");
//               return;
//             }

//             final decodedMessage = jsonDecode(data) as Map<String, dynamic>;
//             print("Received Notification WebSocket message: $decodedMessage");

//             if (decodedMessage['Event'] == 'notification') {
//               if (!_isValidNotificationMessage(decodedMessage)) {
//                 print("Invalid notification message: missing required fields");
//                 return;
//               }
//               final notification = NotificationMessage.fromJson(decodedMessage);
//               _notificationController.add(notification);
//               _onNotificationReceived(notification);
//             } else {
//               print("Unknown message type: ${decodedMessage['Event']}");
//             }
//           } catch (e, stackTrace) {
//             print("Error processing notification message: $e | Data received: $data\n$stackTrace");
//           }
//         },
//         onError: (error) {
//           print("Notification WebSocket error: $error");
//           _isConnected = false;
//           _channel = null;
//           _reconnect(userId);
//         },
//         onDone: () {
//           print(
//             "Notification WebSocket closed by server with code: ${_channel?.closeCode}, reason: ${_channel?.closeReason}",
//           );
//           _isConnected = false;
//           _channel = null;
//           _reconnect(userId);
//         },
//       );

//       // Gửi ping định kỳ để duy trì kết nối
//       _startPing(userId);
//     } catch (e) {
//       print("Error connecting to Notification WebSocket: $e");
//       _isConnected = false;
//       _channel = null;
//       _reconnect(userId);
//     }
//   }

//   bool _isValidNotificationMessage(Map<String, dynamic> message) {
//     return message['SenderId'] != null &&
//         message['Title'] != null &&
//         message['Body'] != null &&
//         message['Type'] != null &&
//         message['Id'] != null;
//   }

//   void _reconnect(int userId) {
//     Future.delayed(const Duration(seconds: 5), () {
//       if (!_isConnected) {
//         print("Attempting to reconnect to $_url...");
//         connect(userId);
//       }
//     });
//   }

//   void _startPing(int userId) {
//     Timer.periodic(const Duration(seconds: 30), (timer) {
//       if (!_isConnected || _channel == null || _channel!.closeCode != null) {
//         timer.cancel();
//         return;
//       }
//       try {
//         final pingMessage = {"type": "ping"};
//         _channel!.sink.add(jsonEncode(pingMessage));
//         print("Sent ping message");
//       } catch (e) {
//         print("Error sending ping message: $e");
//         timer.cancel();
//         _reconnect(userId);
//       }
//     });
//   }

//   void sendBootupMessage(int userId) {
//     if (!_isConnected || _channel == null) {
//       print("Cannot send bootup message: Not connected");
//       return;
//     }

//     try {
//       final bootupMessage = {
//         "type": "bootup",
//         "sender_id": userId,
//       };
//       final jsonMessage = jsonEncode(bootupMessage);
//       _channel!.sink.add(jsonMessage);
//       print("Sent bootup message: $jsonMessage");
//     } catch (e) {
//       print("Error sending bootup message: $e");
//     }
//   }

//   void disconnect() {
//     if (_isConnected && _channel != null) {
//       try {
//         _channel!.sink.close();
//         print("Notification WebSocket connection closed");
//       } catch (e) {
//         print("Error closing Notification WebSocket: $e");
//       } finally {
//         _isConnected = false;
//         _channel = null;
//       }
//     }
//     _notificationController.close();
//   }
// }