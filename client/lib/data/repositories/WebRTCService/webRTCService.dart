import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';

class WebRTCService {
  final WebSocketService _webSocketService;
  final int _userId;
  final int _conversationId;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  WebRTCService(this._webSocketService, this._userId, this._conversationId);

  Future<void> init() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        
      ],
    };
    _peerConnection = await createPeerConnection(config);

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false, // Chỉ âm thanh, thêm video nếu cần
    });

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onIceCandidate = (candidate) {
      _webSocketService.sendIceCandidate(_userId, _conversationId, candidate.toMap());
    };

    _peerConnection!.onTrack = (event) {
      // Xử lý luồng âm thanh từ đối phương
    };
  }

  Future<Map<String, dynamic>> createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer.toMap();
  }

  Future<Map<String, dynamic>> handleOffer(Map<String, dynamic> sdp) async {
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp['sdp'], sdp['type']),
    );
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer.toMap();
  }

  void handleAnswer(Map<String, dynamic> sdp) {
    _peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp['sdp'], sdp['type']),
    );
  }

  void handleIceCandidate(Map<String, dynamic> data) {
    _peerConnection!.addCandidate(
      RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      ),
    );
  }

  void dispose() {
    _peerConnection?.close();
    _localStream?.dispose();
    _peerConnection = null;
    _localStream = null;
  }
}