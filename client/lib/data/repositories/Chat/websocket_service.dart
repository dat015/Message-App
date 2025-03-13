import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  WebSocketChannel? _channel;
  final String url;
  final Function(String) onMessageReceived;
  String? _sessionId;
  bool _isConnected = false;
  late int user_id;

  WebSocketService({required this.user_id, required this.url, required this.onMessageReceived});

  bool get isConnected => _isConnected;
  String? get sessionId => _sessionId;

  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _channel!.stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
    );
  }

  void _onData(dynamic data) {
    print('Raw data received: $data');
    final message = jsonDecode(data as String);
    if (message['session_id'] != null) {
      _sessionId = message['session_id'];
      _isConnected = true;
      send({'user_id': '$user_id'});
      print('Connected with session ID: $_sessionId');
    } else {
      onMessageReceived(data);
    }
  }

  void _onError(error) {
    print('WebSocket error: $error');
    _isConnected = false;
  }

  void _onDone() {
    print('WebSocket closed');
    _isConnected = false;
    Future.delayed(Duration(seconds: 2), () {
      print('Reconnecting...');
      connect();
    });
  }

  void send(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      print('Sending message: ${jsonEncode(message)}');
      _channel!.sink.add(jsonEncode(message));
    } else {
      print('Cannot send message: WebSocket is not connected');
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close(status.goingAway);
      _channel = null;
      _isConnected = false;
    }
  }
}