import 'package:first_app/PlatformClient/config.dart';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  final WebSocketService _webSocketService;
  final int _userId;
  final int _conversationId;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final Function(MediaStream)? onRemoteStreamAdded;
  final List<RTCIceCandidate> _pendingIceCandidates = [];

  WebRTCService(
    this._webSocketService,
    this._userId,
    this._conversationId, {
    this.onRemoteStreamAdded,
  });

  RTCVideoRenderer get localRenderer => _localRenderer;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  Future<void> init() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      print(
        'Renderers initialized: local=${_localRenderer.srcObject}, remote=${_remoteRenderer.srcObject}',
      );
      var ip = Config.localNetworkIP;

      final config = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {
            'urls': 'turn:$ip:3478',
            'username': 'test',
            'credential': 'test',
          },
        ],
        'sdpSemantics': 'unified-plan',
      };

      _peerConnection = await createPeerConnection(config);
      print('PeerConnection created');

      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': true,
      });
      print(
        'Local stream obtained: id=${_localStream?.id}, tracks=${_localStream?.getTracks().map((t) => "${t.kind}: enabled=${t.enabled}").join(", ")}',
      );

      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
        print(
          'Track added: id=${track.id}, kind=${track.kind}, enabled=${track.enabled}',
        );
      });

      _localRenderer.srcObject = _localStream;
      print('Local stream set to renderer');

      _peerConnection?.onIceCandidate = (candidate) {
        if (candidate.candidate != null) {
          print('Sending ICE candidate: ${candidate.toMap()}');
          _webSocketService.sendIceCandidate(
            _userId,
            _conversationId,
            candidate.toMap(),
          );
        }
      };

      _peerConnection?.onTrack = (RTCTrackEvent event) {
        print(
          'onTrack triggered: stream id=${event.streams[0].id}, tracks=${event.streams[0].getTracks().map((t) => "${t.kind}: enabled=${t.enabled}").join(", ")}',
        );
        _remoteStream = event.streams[0];
        _remoteRenderer.srcObject = _remoteStream;
        print('Remote stream set to renderer: id=${_remoteStream?.id}');
        onRemoteStreamAdded?.call(_remoteStream!);
      };

      // _peerConnection?.onAddStream = (stream) {
      //   print(
      //     'onAddStream triggered: stream id=${stream.id}, tracks=${stream.getTracks().map((t) => "${t.kind}: enabled=${t.enabled}").join(", ")}',
      //   );
      //   _remoteStream = stream;
      //   _remoteRenderer.srcObject = _remoteStream;
      //   print('Remote stream set to renderer: id=${_remoteStream?.id}');
      //   onRemoteStreamAdded?.call(_remoteStream!);
      // };

      _peerConnection?.onConnectionState = (state) {
        print('Connection state: $state');
      };

      _peerConnection?.onIceConnectionState = (state) {
        print('ICE connection state: $state');
        if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          print('ICE connection failed, attempting to restart ICE');
          _peerConnection?.restartIce();
        }
      };
    } catch (e) {
      print('Error initializing WebRTC: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createOffer() async {
    if (_peerConnection == null) throw 'PeerConnection is not initialized';
    try {
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });
      await _peerConnection!.setLocalDescription(offer);
      print('Offer created: ${offer.toMap()}');
      return offer.toMap();
    } catch (e) {
      print('Error creating offer: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> handleOffer(Map<String, dynamic> sdp) async {
    if (_peerConnection == null) throw 'PeerConnection is not initialized';
    try {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdp['sdp'], sdp['type']),
      );
      print('Remote description set for offer: ${sdp['sdp']}');
      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });
      await _peerConnection!.setLocalDescription(answer);
      print('Answer created: ${answer.toMap()}');
      for (var candidate in _pendingIceCandidates) {
        await _peerConnection!.addCandidate(candidate);
        print('Added pending ICE candidate: ${candidate.candidate}');
      }
      _pendingIceCandidates.clear();
      return answer.toMap();
    } catch (e) {
      print('Error handling offer: $e');
      rethrow;
    }
  }

  Future<void> handleAnswer(Map<String, dynamic> sdp) async {
    if (_peerConnection == null) throw 'PeerConnection is not initialized';
    try {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdp['sdp'], sdp['type']),
      );
      print('Remote description set for answer: ${sdp['sdp']}');
      for (var candidate in _pendingIceCandidates) {
        await _peerConnection!.addCandidate(candidate);
        print('Added pending ICE candidate: ${candidate.candidate}');
      }
      _pendingIceCandidates.clear();
    } catch (e) {
      print('Error handling answer: $e');
    }
  }

  void handleIceCandidate(Map<String, dynamic> data) {
    if (_peerConnection == null) return;
    try {
      final candidate = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );
      _peerConnection!.getRemoteDescription().then((remoteDesc) {
        if (remoteDesc != null) {
          _peerConnection!.addCandidate(candidate);
          print('ICE candidate added: ${data['candidate']}');
        } else {
          print(
            'Remote description not set, queuing ICE candidate: ${data['candidate']}',
          );
          _pendingIceCandidates.add(candidate);
        }
      });
    } catch (e) {
      print('Error handling ICE candidate: $e');
    }
  }

  void dispose() {
    _peerConnection?.close();
    _localStream?.dispose();
    _remoteStream?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
    _pendingIceCandidates.clear();
    print('WebRTCService disposed');
  }
}
