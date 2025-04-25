import 'package:first_app/data/repositories/WebRTCService/webRTCService.dart';
import 'package:flutter/material.dart';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';
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
      if (event['event'] == 'receiveCall') {
        _handleIncomingCall(
          callerId: event['callerId'],
          conversationId: event['conversationId'],
          name: event['name'],
          offerType: event['offerType'],
          sdp: event['sdp'],
        );
      } else if (event['event'] == 'callAccepted') {
        _webRTCService?.handleAnswer(event['sdp']);
        isCalling = true;
        notifyListeners();
      } else if (event['event'] == 'iceCandidate') {
        _webRTCService?.handleIceCandidate(event['data']);
      } else if (event['event'] == 'callEnded') {
        print("call ended");
        isCalling = false;
        _webRTCService?.dispose();
        currentConversationId = null;
        currentUserId = null;
        callerName = null;
        notifyListeners();
      }
    });
  }

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
    print("Bat dau cuoc goi");
   
  webSocketService.connect(userId, conversationId);


    try {
      if (!await Permission.microphone.request().isGranted) {
        throw 'Quyền micro bị từ chối';
      }
      _webRTCService = WebRTCService(webSocketService, userId, conversationId);
      await _webRTCService!.init();
      final offer = await _webRTCService!.createOffer();
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
      print("Dang trong cuoc goi: $isCalling");
      _showSnackBar('Đang gọi nhóm...');
    } catch (e) {
      isCalling = false;
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
      builder:
          (context) => AlertDialog(
            title: const Text('Cuộc gọi đến'),
            content: Text('$name đang gọi bạn ($offerType).'),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    if (!await Permission.microphone.request().isGranted) {
                      throw 'Quyền micro bị từ chối';
                    }
                    _webRTCService = WebRTCService(
                      webSocketService,
                      callerId,
                      conversationId,
                    );
                    await _webRTCService!.init();
                    final answer = await _webRTCService!.handleOffer(sdp);
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
                    _showSnackBar('Lỗi khi chấp nhận cuộc gọi: $e');
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
    webSocketService.endCall(currentUserId!, currentConversationId!);
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
    _callEventSubscription?.cancel();
    _webRTCService?.dispose();
    super.dispose();
  }
}
