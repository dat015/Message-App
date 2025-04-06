import 'dart:convert';
import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/models/messages.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final String _url;
  final Function(MessageWithAttachment) onMessageReceived;
  bool _isConnected = false;

  WebSocketService({required String url, required this.onMessageReceived})
    : _url = url;

  void connect(int userId, int conversationId) {
    if (_isConnected) {
      print("WebSocket already connected to $_url");
      return;
    }

    try {
      print("Attempting to connect to WebSocket at: $_url");
      _channel = WebSocketChannel.connect(Uri.parse(_url));
      _isConnected = true;
      print("WebSocket connection established");

      _sendBootupMessage(userId, conversationId);

      _channel!.stream.listen(
        (data) {
          try {
            if (data == "ping") {
              print("Received ping message, ignoring...");
              return;
            }

            // Decode JSON từ WebSocket
            final decodedMessage = jsonDecode(data) as Map<String, dynamic>;

            // Chuyển đổi tất cả key thành lowercase
            final lowercaseMessage = _convertKeysToLowercase(decodedMessage);

            // Parse dữ liệu với key lowercase
            final messageWithAttachment = MessageWithAttachment.fromJson(
              lowercaseMessage,
            );
            print("Received message: $data");
            onMessageReceived(messageWithAttachment);
          } catch (e) {
            print("Error processing message: $e | Data received: $data");
          }
        },
        onError: (error) {
          print("WebSocket error: $error");
          _isConnected = false;
          _channel = null;
          _reconnect(userId, conversationId);
        },
        onDone: () {
          print(
            "WebSocket closed by server with code: ${_channel?.closeCode}, reason: ${_channel?.closeReason}",
          );
          _isConnected = false;
          _channel = null;
          _reconnect(userId, conversationId);
        },
      );
    } catch (e) {
      print("Error connecting to WebSocket: $e");
      _isConnected = false;
      _channel = null;
      _reconnect(userId, conversationId);
    }
  }

  Map<String, dynamic> _convertKeysToLowercase(Map<String, dynamic> input) {
    return input.map((key, value) {
      if (value is Map<String, dynamic>) {
        // Đệ quy nếu value là một Map khác (như "Message" hoặc "Attachment")
        return MapEntry(key.toLowerCase(), _convertKeysToLowercase(value));
      }
      // Trả về key lowercase và giữ nguyên value nếu không phải Map
      return MapEntry(key.toLowerCase(), value);
    });
  }

  void _reconnect(int userId, int conversationId) {
    Future.delayed(Duration(seconds: 5), () {
      if (!_isConnected) {
        print("Attempting to reconnect to $_url...");
        connect(userId, conversationId);
      }
    });
  }

  void _sendBootupMessage(int userId, int conversationId) {
    if (!_isConnected || _channel == null) {
      print("Cannot send bootup message: Not connected");
      return;
    }

    try {
      final bootupMessage = {
        "type": "bootup",
        "sender_id": userId,
        "conversation_id": conversationId,
      };
      final jsonMessage = jsonEncode(bootupMessage);
      _channel!.sink.add(jsonMessage);
      print("Sent bootup message: $jsonMessage");
    } catch (e) {
      print("Error sending bootup message: $e");
    }
  }

  void sendMessage(
    int userId,
    int conversationId,
    String content,
    int? fileID,
  ) {
    if (!_isConnected || _channel == null) {
      print("Cannot send message: Not connected");
      return;
    }
    try {
      final message = {
        "type": "message",
        "sender_id": userId,
        "conversation_id": conversationId,
        "content": content,
        "created_at": DateTime.now().toIso8601String(),
        "fileID": fileID,
      };
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      print("Sent group message: $jsonMessage");
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  void sendPrivateMessage(
    int userId,
    int conversationId,
    int recipientId,
    String content,
    int? fileID,
  ) {
    if (!_isConnected || _channel == null) {
      print("Cannot send private message: Not connected");
      return;
    }
    try {
      final message = {
        "type": "private",
        "sender_id": userId,
        "conversation_id": conversationId,
        "content": "recipient_id:$recipientId,$content",
        "created_at": DateTime.now().toIso8601String(),
        "fileID": fileID,
      };
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      print("Sent private message: $jsonMessage");
    } catch (e) {
      print("Error sending private message: $e");
    }
  }

  void disconnect() {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.close();
        print("WebSocket connection closed");
      } catch (e) {
        print("Error closing WebSocket: $e");
      } finally {
        _isConnected = false;
        _channel = null;
      }
    }
  }
}
