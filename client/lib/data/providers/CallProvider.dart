import 'package:first_app/data/repositories/WebRTCService/webRTCService.dart';
import 'package:flutter/material.dart';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:first_app/main.dart';

class CallProvider extends ChangeNotifier {
  final WebSocketService webSocketService;
  WebRTCService? _webRTCService;
  bool isCalling = false;
  int? currentConversationId;
  int? currentUserId;
  String? callerName;
  StreamSubscription<Map<String, dynamic>>? _callEventSubscription;

  CallProvider({required this.webSocketService}) {
    _callEventSubscription = webSocketService.callEvents.listen((event) {
      print('Received call event: $event');
      if (event['event'] == 'receiveCall') {
        _handleIncomingCall(
          callerId: event['callerId'],
          conversationId: event['conversationId'],
          name: event['name'],
          offerType: event['offerType'],
          sdp: event['sdp'],
        );
      } else if (event['event'] == 'callAccepted') {
        print('Call accepted, handling answer: ${event['sdp']}');
        if (_webRTCService != null) {
          _webRTCService!.handleAnswer(event['sdp']);
          isCalling = true;
          notifyListeners();
        } else {
          print('Error: WebRTCService is null when handling callAccepted');
        }
      } else if (event['event'] == 'iceCandidate') {
        print('Handling ICE candidate: ${event['data']}');
        _webRTCService?.handleIceCandidate(event['data']);
      } else if (event['event'] == 'callEnded') {
        print('Call ended');
        _endCallCleanup();
      } else if (event['event'] == 'error') {
        print('Call error: ${event['content']}');
        _showSnackBar('Lỗi cuộc gọi: ${event['content']}');
      }
    });
  }

  RTCVideoRenderer? get localRenderer => _webRTCService?.localRenderer;
  RTCVideoRenderer? get remoteRenderer => _webRTCService?.remoteRenderer;

  Future<void> startCall(
    int userId,
    int conversationId,
    String name,
    String offerType,
  ) async {
    if (isCalling) {
      _showSnackBar('Bạn đang trong một cuộc gọi!');
      return;
    }

    try {
      if (!await Permission.microphone.request().isGranted) {
        throw 'Quyền micro bị từ chối';
      }
      if (!await Permission.camera.request().isGranted) {
        throw 'Quyền camera bị từ chối';
      }

      if(webSocketService.isConnected == false) {
        webSocketService.connect(userId, conversationId);
      }
      _webRTCService = WebRTCService(
        webSocketService,
        userId,
        conversationId,
        onRemoteStreamAdded: (stream) {
          print('Remote stream added in CallProvider');
          notifyListeners();
        },
      );

      await _webRTCService!.init();
      final offer = await _webRTCService!.createOffer();
      print('Starting call with offer: $offer');
      webSocketService.startCall(
        userId,
        conversationId,
        name,
        offerType,
        offer,
      );

      isCalling = true;
      currentConversationId = conversationId;
      currentUserId = userId;
      callerName = name;
      notifyListeners();
      _showSnackBar('Đang gọi nhóm...');
    } catch (e) {
      print('Error starting call: $e');
      isCalling = false;
      _webRTCService?.dispose();
      _showSnackBar('Lỗi khi bắt đầu cuộc gọi: $e');
    }
  }

  void _handleIncomingCall({
    required int callerId,
    required int conversationId,
    required String name,
    required String offerType,
    required Map<String, dynamic> sdp,
  }) {
    if (isCalling) {
      print('Đã trong cuộc gọi, bỏ qua cuộc gọi từ $callerId');
      return;
    }

    showDialog(
      context: MyApp.navigatorKey.currentState!.overlay!.context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Cuộc gọi đến'),
        content: Text('$name đang gọi bạn ($offerType).'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                if (!await Permission.microphone.request().isGranted) {
                  throw 'Quyền micro bị từ chối';
                }
                if (!await Permission.camera.request().isGranted) {
                  throw 'Quyền camera bị từ chối';
                }

                _webRTCService = WebRTCService(
                  webSocketService,
                  callerId,
                  conversationId,
                  onRemoteStreamAdded: (stream) {
                    print('Remote stream added in CallProvider');
                    notifyListeners();
                  },
                );

                await _webRTCService!.init();
                final answer = await _webRTCService!.handleOffer(sdp);
                print('Sending acceptCall with answer: $answer');
                webSocketService.acceptCall(
                  callerId,
                  conversationId,
                  name,
                  offerType,
                  answer,
                );

                isCalling = true;
                currentConversationId = conversationId;
                currentUserId = callerId;
                callerName = name;
                notifyListeners();
                Navigator.of(context).pop();
                _showSnackBar('Đã tham gia cuộc gọi');
              } catch (e) {
                print('Error accepting call: $e');
                _showSnackBar('Lỗi khi chấp nhận cuộc gọi: $e');
                Navigator.of(context).pop();
              }
            },
            child: const Text('Chấp nhận'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  void endCall() {
    if (!isCalling || currentUserId == null || currentConversationId == null) {
      return;
    }
    print('Ending call: userId=$currentUserId, conversationId=$currentConversationId');
    webSocketService.endCall(currentUserId!, currentConversationId!);
    _endCallCleanup();
  }

  void _endCallCleanup() {
    print('Cleaning up call');
    _webRTCService?.dispose();
    isCalling = false;
    currentConversationId = null;
    currentUserId = null;
    callerName = null;
    notifyListeners();
    _showSnackBar('Cuộc gọi đã kết thúc');
  }

  void _showSnackBar(String message) {
    final scaffoldMessenger = ScaffoldMessenger.of(
      MyApp.navigatorKey.currentState!.context,
    );
    scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    print('Disposing CallProvider');
    _callEventSubscription?.cancel();
    _webRTCService?.dispose();
    super.dispose();
  }
}