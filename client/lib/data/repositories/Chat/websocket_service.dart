import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  // Singleton instance
  static final WebSocketService _instance = WebSocketService._internal();
  
  // Factory constructor để trả về instance duy nhất
  factory WebSocketService({
    required int userId,
    required String url,
    required Function(Map<String, dynamic>) onMessageReceived,
    required Function(bool) onConnectionStateChanged,
  }) {
    _instance.userId = userId;
    _instance.url = url;
    _instance.onMessageReceived = onMessageReceived;
    _instance.onConnectionStateChanged = onConnectionStateChanged;
    return _instance;
  }

  // Private constructor
  WebSocketService._internal();

  WebSocketChannel? _channel;
  late String url;
  late Function(Map<String, dynamic>) onMessageReceived;
  late Function(bool) onConnectionStateChanged;
  String? _sessionId;
  bool _isConnected = false;
  bool _isManuallyDisconnected = false;
  late int userId;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectDelay = const Duration(seconds: 2);

  // StreamController cho tin nhắn và trạng thái kết nối
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  // Getter để truy cập Stream
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<bool> get onConnectionState => _connectionStateController.stream;

  bool get isConnected => _isConnected;
  String? get sessionId => _sessionId;

  void connect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnect attempts reached. Stopping reconnection.');
      _connectionStateController.add(false);
      return;
    }

    try {
      final uri = Uri.parse('$url?userId=$userId');
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      _isConnected = false;
      _connectionStateController.add(false);
      _onDone();
    }
  }

  void _onData(dynamic data) {
    try {
      print('Raw data received: $data');
      final message = jsonDecode(data as String);
      if (message['session_id'] != null) {
        _sessionId = message['session_id'];
        _isConnected = true;
        _reconnectAttempts = 0;
        onConnectionStateChanged(true);
        _connectionStateController.add(true);
        send({'user_id': userId.toString()});
        print('Connected with session ID: $_sessionId');
      } else {
        onMessageReceived(message);
        _messageController.add(message);
      }
    } catch (e) {
      print('Error decoding WebSocket message: $e');
    }
  }

  void _onError(error) {
    print('WebSocket error: $error');
    _isConnected = false;
    _connectionStateController.add(false);
  }

  void _onDone() {
    print('WebSocket closed');
    _isConnected = false;
    _connectionStateController.add(false);

    if (!_isManuallyDisconnected) {
      Future.delayed(_reconnectDelay, () {
        if (_reconnectAttempts < _maxReconnectAttempts) {
          print('Reconnecting... Attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts');
          _reconnectAttempts++;
          connect();
        } else {
          print('Max reconnect attempts reached. Stopping reconnection.');
        }
      });
    } else {
      print('WebSocket was manually disconnected. No reconnection attempts will be made.');
    }
  }

  void send(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      print('Sending message: ${jsonEncode(message)}');
      _channel!.sink.add(jsonEncode(message));
    } else {
      print('Cannot send message: WebSocket is not connected');
      if (!_isConnected && !_isManuallyDisconnected) {
        print('Attempting to reconnect before sending message...');
        connect();
      }
    }
  }

  void disconnect() {
    if (_channel != null) {
      try {
        _isManuallyDisconnected = true;
        _channel!.sink.close(status.normalClosure, 'Normal closure');
        _channel = null;
        _isConnected = false;
        _reconnectAttempts = 0;
        _connectionStateController.add(false);
      } catch (e) {
        print('Error closing WebSocket: $e');
      } finally {
        _messageController.close();
        _connectionStateController.close();
      }
    }
  }

  // Phương thức để reset trạng thái khi đăng xuất
  void reset() {
    disconnect();
    _isManuallyDisconnected = false;
    _reconnectAttempts = 0;
    _sessionId = null;
  }
}