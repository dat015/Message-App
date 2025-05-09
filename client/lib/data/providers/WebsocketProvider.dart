import 'package:flutter/material.dart';
import '../repositories/Chat/websocket_service.dart';
import '../dto/message_response.dart';

class WebSocketProvider extends ChangeNotifier {
  final WebSocketService _webSocketService;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  WebSocketProvider(String url)
      : _webSocketService = WebSocketService(
          url: url,
          onMessageReceived: (MessageWithAttachment message) {
            // Xử lý tin nhắn
          },
          onReceiveCall: (conversationId) {
            // Xử lý khi nhận cuộc gọi
          },
          onCallAccepted: (conversationId) {
            // Xử lý khi cuộc gọi được chấp nhận
          },
          onReceiveOffer: (conversationId, sdp) {
            // Xử lý khi nhận offer
          },
          onReceiveAnswer: (conversationId, sdp) {
            // Xử lý khi nhận answer
          },
          onReceiveIceCandidate: (conversationId, candidate) {
            // Xử lý ICE candidate
          },
          onCallEnded: (conversationId) {
            // Xử lý khi cuộc gọi kết thúc
          },
        );

  final List<MessageWithAttachment> _messages = [];
  List<MessageWithAttachment> get messages => _messages;

  void connect(int userId, int conversationId) {
    if (!_isConnected) {
      _webSocketService.connect(userId, conversationId);
      _isConnected = true;
      notifyListeners();
    }
  }

  void disconnect() {
    if (_isConnected) {
      // _webSocketService.disconnect();
      // _isConnected = false;
      notifyListeners();
    }
  }

  void handleMessage(MessageWithAttachment message) {
    _messages.add(message); // Lưu tin nhắn mới vào danh sách
    notifyListeners(); // Thông báo cho UI hoặc màn hình
  }

  void handleReceiveCall(int conversationId) {
    // Xử lý sự kiện nhận cuộc gọi
    print('Received call for conversation: $conversationId');
    notifyListeners();
  }

  void handleCallAccepted(int conversationId) {
    // Xử lý sự kiện khi cuộc gọi được chấp nhận
    print('Call accepted for conversation: $conversationId');
    notifyListeners();
  }

  void handleReceiveOffer(int conversationId, String sdp) {
    // Xử lý sự kiện nhận offer
    print('Received offer for conversation: $conversationId, SDP: $sdp');
    notifyListeners();
  }

  void handleReceiveAnswer(int conversationId, String sdp) {
    // Xử lý sự kiện nhận answer
    print('Received answer for conversation: $conversationId, SDP: $sdp');
    notifyListeners();
  }

  void handleReceiveIceCandidate(int conversationId, Map<String, dynamic> candidate) {
    // Xử lý sự kiện nhận ICE candidate
    print('Received ICE candidate for conversation: $conversationId');
    notifyListeners();
  }

  void handleCallEnded(int conversationId) {
    // Xử lý sự kiện khi cuộc gọi kết thúc
    print('Call ended for conversation: $conversationId');
    notifyListeners();
  }

  WebSocketService get service => _webSocketService;
}