import 'dart:async';
import 'dart:convert';
import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/models/messages.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final String _url;
  Function(MessageWithAttachment) onMessageReceived;
  Function(int)? onReceiveCall; // Loại bỏ final
  Function(int)? onCallAccepted; // Loại bỏ final
  Function(int, String)? onReceiveOffer; // Loại bỏ final
  Function(int, String)? onReceiveAnswer; // Loại bỏ final
  Function(int, String)? onReceiveIceCandidate; // Loại bỏ final
  Function(int)? onCallEnded; // Loại bỏ final
  bool _isConnected = false;
  // Thêm StreamController để phát sự kiện cuộc gọi
  final StreamController<Map<String, dynamic>> _callEvents =
      StreamController.broadcast();

  // Getter cho callEvents
  Stream<Map<String, dynamic>> get callEvents => _callEvents.stream;
  WebSocketService({
    required String url,
    required this.onMessageReceived,
    this.onReceiveCall,
    this.onCallAccepted,
    this.onReceiveOffer,
    this.onReceiveAnswer,
    this.onReceiveIceCandidate,
    this.onCallEnded,
  }) : _url = url;

  void connect(int userId, int conversationId) {
    if (_isConnected) {
      print("WebSocket already connected to $_url");
      return;
    }

    try {
      print("Attempting to connect to WebSocket at: $_url");
      _channel = WebSocketChannel.connect(Uri.parse('$_url?userId=$userId'));
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

            final decodedMessage = jsonDecode(data) as Map<String, dynamic>;
            print("Received WebSocket message: $decodedMessage");

            if (decodedMessage['type'] == 'receiveCall') {
              if (!_isValidReceiveCallMessage(decodedMessage)) {
                print("Invalid receiveCall message: missing required fields");
                return;
              }
              _callEvents.add({
                'event': 'receiveCall',
                'callerId': decodedMessage['sender_id'],
                'conversationId': decodedMessage['conversation_id'],
                'name': decodedMessage['name'],
                'offerType': decodedMessage['offerType'],
                'sdp': {
                  'sdp': decodedMessage['sdp']['sdp'],
                  'type': decodedMessage['sdp']['type'],
                },
              });
            } else if (decodedMessage['type'] == 'callAccepted') {
              if (!_isValidCallAcceptedMessage(decodedMessage)) {
                print("Invalid callAccepted message: missing required fields");
                return;
              }
              _callEvents.add({
                'event': 'callAccepted',
                'sdp': decodedMessage['sdp'],
                'name': decodedMessage['name'],
                'answerType': decodedMessage['answerType'],
              });
            } else if (decodedMessage['type'] == 'iceCandidate') {
              if (!_isValidIceCandidateMessage(decodedMessage)) {
                print("Invalid iceCandidate message: missing required fields");
                return;
              }
              _callEvents.add({
                'event': 'iceCandidate',
                'data': decodedMessage['data'],
              });
            } else if (decodedMessage['type'] == 'callEnded') {
              _callEvents.add({'event': 'callEnded'});
            } else if (decodedMessage['type'] == 'error') {
              _callEvents.add({
                'event': 'error',
                'content': decodedMessage['content'] ?? 'Unknown error',
              });
            } else {
              final lowercaseMessage = _convertKeysToLowercase(decodedMessage);
              final messageWithAttachment = MessageWithAttachment.fromJson(
                lowercaseMessage,
              );
              print("Received chat message: $data");
              onMessageReceived(messageWithAttachment);
            }
          } catch (e, stackTrace) {
            print("Error processing message: $e | Data received: $data\n$stackTrace");
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

  bool _isValidReceiveCallMessage(Map<String, dynamic> message) {
    final sdp = message['sdp'];
    return message['sender_id'] != null &&
        message['conversation_id'] != null &&
        message['name'] != null &&
        message['offerType'] != null &&
        sdp != null &&
        sdp is Map<String, dynamic> &&
        sdp['sdp'] != null &&
        sdp['type'] != null;
  }

  bool _isValidCallAcceptedMessage(Map<String, dynamic> message) {
    final sdp = message['sdp'];
    return message['sender_id'] != null &&
        message['conversation_id'] != null &&
        message['name'] != null &&
        message['answerType'] != null &&
        sdp != null &&
        sdp is Map<String, dynamic> &&
        sdp['sdp'] != null &&
        sdp['type'] != null;
  }

  bool _isValidIceCandidateMessage(Map<String, dynamic> message) {
    final data = message['data'];
    return data != null &&
        data is Map<String, dynamic> &&
        data['candidate'] != null &&
        data['sdpMid'] != null &&
        data['sdpMLineIndex'] != null;
  }

  Map<String, dynamic> _convertKeysToLowercase(Map<String, dynamic> input) {
    return input.map((key, value) {
      if (value is Map<String, dynamic>) {
        return MapEntry(key.toLowerCase(), _convertKeysToLowercase(value));
      }
      return MapEntry(key.toLowerCase(), value);
    });
  }

  void _reconnect(int userId, int conversationId) {
    Future.delayed(const Duration(seconds: 5), () {
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

  void addMember(int userId, int conversationId) {
    if (!_isConnected || _channel == null) {
      print("Cannot add member: Not connected");
      return;
    }
    try {
      final message = {
        "type": "system_addMember",
        "sender_id": userId,
        "conversation_id": conversationId,
      };
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      print("Sent add member message: $jsonMessage");
    } catch (e) {
      print("Error sending add member message: $e");
    }
  }

  void startCall(
    int userId,
    int conversationId,
    String name,
    String offerType,
    Map<String, dynamic> sdp,
  ) {
    if (!_isConnected || _channel == null) {
      print("Cannot start call: Not connected");
      print("Ket noi dang mo: $_isConnected");
      return;
    }
    print("start call");
    try {
      final message = {
        'type': 'startCall',
        'sender_id': userId,
        'conversation_id': conversationId,
        'name': name,
        'offerType': offerType,
        'sdp': sdp,
      };
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      print("Sent start call message: $jsonMessage");
    } catch (e) {
      print("Error sending start call message: $e");
    }
  }

  void acceptCall(
    int userId,
    int conversationId,
    String name,
    String answerType,
    Map<String, dynamic> sdp,
  ) {
    if (!_isConnected || _channel == null) {
      print("Cannot accept call: Not connected");
      return;
    }

    try {
      final message = {
        'type': 'acceptCall',
        'sender_id': userId,
        'conversation_id': conversationId,
        'name': name,
        'answerType': answerType,
        'sdp': sdp,
      };
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      print("Sent accept call message: $jsonMessage");
    } catch (e) {
      print("Error sending accept call message: $e");
    }
  }

  void sendOffer(int userId, int conversationId, String offer) {
    if (!_isConnected || _channel == null) {
      print("Cannot send offer: Not connected");
      return;
    }
    try {
      final message = {
        "type": "offer",
        "sender_id": userId,
        "conversation_id": conversationId,
        "content": offer,
      };
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      print("Sent offer message: $jsonMessage");
    } catch (e) {
      print("Error sending offer message: $e");
    }
  }

  void sendAnswer(
    int userId,
    int conversationId,
    int recipientId,
    String answer,
  ) {
    if (!_isConnected || _channel == null) {
      print("Cannot send answer: Not connected");
      return;
    }
    try {
      final message = {
        "type": "answer",
        "sender_id": userId,
        "conversation_id": conversationId,
        "recipient_id": recipientId,
        "content": answer,
      };
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      print("Sent answer message: $jsonMessage");
    } catch (e) {
      print("Error sending answer message: $e");
    }
  }

  void sendIceCandidate(
    int userId,
    int conversationId,
    Map<String, dynamic> candidate,
  ) {
    if (!_isConnected || _channel == null) {
      print("Cannot send ICE candidate: Not connected");
      return;
    }
    try {
      final message = {
        "type": "iceCandidate",
        "sender_id": userId,
        "conversation_id": conversationId,
        'data': candidate,
      };
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      print("Sent ICE candidate message: $jsonMessage");
    } catch (e) {
      print("Error sending ICE candidate message: $e");
    }
  }

  void endCall(int userId, int conversationId) {
    if (!_isConnected || _channel == null) {
      print("Cannot end call: Not connected");
      return;
    }
    try {
      final message = {
        "type": "endCall",
        "sender_id": userId,
        "conversation_id": conversationId,
      };
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      print("Sent end call message: $jsonMessage");
    } catch (e) {
      print("Error sending end call message: $e");
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
        print("Dong ket noi");
        _isConnected = false;
        _channel = null;
      }
    }
  }
}
