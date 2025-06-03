// import 'dart:convert';
// import 'package:first_app/data/repositories/Chat/websocket_service.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:permission_handler/permission_handler.dart';

// class VideoCallService {
//   final WebSocketService _webSocketService;
//   MediaStream? _localStream;
//   Map<int, List<MediaStream>> _remoteStreams = {};
//   Map<int, Map<int, RTCPeerConnection>> _peerConnections = {};
//   Map<int, bool> _micEnabled = {};
//   Map<int, bool> _cameraEnabled = {};
//   int? _userId;
//   String? _userName;
//   Map<int, bool> _isRoomCreated = {};
//   Map<int, bool> _isRoomJoined = {};

//   final Function(int, List<MediaStream>) onRemoteStreamsChanged;
//   final Function(int, bool, bool) onMediaControlChanged;
//   final Function(int, String) onError;

//   VideoCallService({
//     required WebSocketService webSocketService,
//     required this.onRemoteStreamsChanged,
//     required this.onMediaControlChanged,
//     required this.onError,
//   }) : _webSocketService = webSocketService {
//     _setupWebSocketListeners();
//   }
 
//   void _setupWebSocketListeners() {
//     _webSocketService.callEvents.listen((event) {
//       final conversationId = event['conversation_id'] as int;
//       switch (event['event']) {
//         case 'roomCreated':
//           _isRoomCreated[conversationId] = true;
//           break;
//         case 'roomJoined':
//           _isRoomJoined[conversationId] = true;
//           final participants = event['participants'] as List<int>;
//           for (var participant in participants) {
//             if (participant != _userId) {
//               _createOffer(conversationId, participant);
//             }
//           }
//           break;
//         case 'userJoined':
//           _createOffer(conversationId, event['sender_id']);
//           break;
//         case 'offer':
//           _handleOffer(conversationId, event['sender_id'], event['sdp'], event['offerType']);
//           break;
//         case 'callAccepted':
//           _handleAnswer(conversationId, event['sender_id'], event['sdp'], event['answerType']);
//           break;
//         case 'iceCandidate':
//           _handleIceCandidate(conversationId, event['sender_id'], event['data']);
//           break;
//         case 'userLeft':
//           _handleUserLeft(conversationId, event['sender_id']);
//           break;
//         case 'mediaControl':
//           _handleMediaControl(conversationId, event['sender_id'], event['micEnabled'], event['cameraEnabled']);
//           break;
//         case 'error':
//           onError(conversationId, event['content']);
//           break;
//       }
//     });
//   }

//   Future<void> requestPermissions() async {
//     await [Permission.camera, Permission.microphone].request();
//     await _openMediaDevices();
//   }

//   Future<void> _openMediaDevices() async {
//     _localStream = await navigator.mediaDevices.getUserMedia({
//       'audio': true,
//       'video': true,
//     });
//   }

//   Future<bool> createRoom(int conversationId, int userId, String userName) async {
//     _userId = userId;
//     _userName = userName;
//     _isRoomCreated[conversationId] = false;
//     _micEnabled[conversationId] = true;
//     _cameraEnabled[conversationId] = true;
//     _remoteStreams[conversationId] = [];
//     _peerConnections[conversationId] = {};

//     if (!_webSocketService.isConnected) {
//       _webSocketService.connect(userId);
//     }
//     _webSocketService.sendCreateRoom(userId, conversationId, userName);

//     await Future.any([
//       Future.delayed(Duration(seconds: 10)),
//       Future.doWhile(() async {
//         await Future.delayed(Duration(milliseconds: 100));
//         return !_isRoomCreated[conversationId]!;
//       }),
//     ]);

//     return _isRoomCreated[conversationId] ?? false;
//   }

//   Future<List<int>?> joinRoom(int conversationId, int userId, String userName) async {
//     _userId = userId;
//     _userName = userName;
//     _isRoomJoined[conversationId] = false;
//     _micEnabled[conversationId] = true;
//     _cameraEnabled[conversationId] = true;
//     _remoteStreams[conversationId] = [];
//     _peerConnections[conversationId] = {};

//     if (!_webSocketService.isConnected) {
//       _webSocketService.connect(userId);
//     }
//     _webSocketService.sendJoinRoom(userId, conversationId, userName);

//     List<int>? participants;
//     await Future.any([
//       Future.delayed(Duration(seconds: 10)),
//       Future.doWhile(() async {
//         await Future.delayed(Duration(milliseconds: 100));
//         if (_isRoomJoined[conversationId] == true) {
//           final event = await _webSocketService.callEvents.firstWhere(
//             (event) => event['event'] == 'roomJoined' && event['conversation_id'] == conversationId,
//             orElse: () => {'participants': []},
//           );
//           participants = event['participants'];
//           return false;
//         }
//         return true;
//       }),
//     ]);

//     return participants;
//   }

//   Future<void> _createOffer(int conversationId, int peerId) async {
//     final peerConnection = await _createPeerConnection(conversationId, peerId);
//     final offer = await peerConnection.createOffer({});
//     await peerConnection.setLocalDescription(offer);
//     _webSocketService.sendOffer(_userId!, conversationId, jsonEncode(offer.toMap()), 'offer', peerId, _userName!);
//   }

//   Future<void> _handleOffer(int conversationId, int senderId, String sdpJson, String offerType) async {
//     final peerConnection = await _createPeerConnection(conversationId, senderId);
//     final offer = RTCSessionDescription(jsonDecode(sdpJson)['sdp'], offerType);
//     await peerConnection.setRemoteDescription(offer);
//     final answer = await peerConnection.createAnswer();
//     await peerConnection.setLocalDescription(answer);
//     _webSocketService.sendAnswer(_userId!, conversationId, jsonEncode(answer.toMap()), 'answer', senderId, _userName!);
//   }

//   Future<void> _handleAnswer(int conversationId, int senderId, String sdpJson, String answerType) async {
//     final peerConnection = _peerConnections[conversationId]?[senderId];
//     final answer = RTCSessionDescription(jsonDecode(sdpJson)['sdp'], answerType);
//     await peerConnection?.setRemoteDescription(answer);
//   }

//   Future<void> _handleIceCandidate(int conversationId, int senderId, IceCandidateData iceData) async {
//     final peerConnection = _peerConnections[conversationId]?[senderId];
//     final candidate = RTCIceCandidate(
//       iceData.candidate,
//       iceData.sdpMid,
//       iceData.sdpMLineIndex,
//     );
//     await peerConnection?.addCandidate(candidate);
//   }

//   Future<void> _handleUserLeft(int conversationId, int senderId) async {
//     final peerConnection = _peerConnections[conversationId]?[senderId];
//     peerConnection?.close();
//     _peerConnections[conversationId]?.remove(senderId);
//     _remoteStreams[conversationId]?.removeWhere((stream) => stream.id.contains(senderId.toString()));
//     onRemoteStreamsChanged(conversationId, _remoteStreams[conversationId] ?? []);
//   }

//   Future<void> _handleMediaControl(int conversationId, int senderId, bool mic, bool camera) async {
//     onMediaControlChanged(conversationId, mic, camera);
//   }

//   Future<RTCPeerConnection> _createPeerConnection(int conversationId, int peerId) async {
//     final configuration = {
//       'iceServers': [
//         {'urls': 'stun:stun.l.google.com:19302'},
//       ]
//     };
//     final peerConnection = await createPeerConnection(configuration);
//     _localStream?.getTracks().forEach((track) {
//       peerConnection.addTrack(track, _localStream!);
//     });

//     peerConnection.onIceCandidate = (candidate) {
//       if (candidate.candidate != null) {
//         _webSocketService.sendIceCandidate(
//           _userId!,
//           conversationId,
//           IceCandidateData(
//             candidate: candidate.candidate!,
//             sdpMid: candidate.sdpMid!,
//             sdpMLineIndex: candidate.sdpMLineIndex!,
//           ),
//           peerId,
//           _userName!,
//         );
//       }
//     };

//     peerConnection.onTrack = (event) {
//       if (event.streams.isNotEmpty) {
//         _remoteStreams[conversationId] ??= [];
//         if (!_remoteStreams[conversationId]!.contains(event.streams[0])) {
//           _remoteStreams[conversationId]!.add(event.streams[0]);
//           onRemoteStreamsChanged(conversationId, _remoteStreams[conversationId]!);
//         }
//       }
//     };

//     _peerConnections[conversationId] ??= {};
//     _peerConnections[conversationId]![peerId] = peerConnection;
//     return peerConnection;
//   }

//   Future<void> toggleMicrophone(int conversationId) async {
//     _micEnabled[conversationId] = !(_micEnabled[conversationId] ?? true);
//     _localStream?.getAudioTracks().forEach((track) {
//       track.enabled = _micEnabled[conversationId]!;
//     });
//     _webSocketService.sendMediaControl(
//       _userId!,
//       conversationId,
//       _micEnabled[conversationId]!,
//       _cameraEnabled[conversationId] ?? true,
//       _userName!,
//     );
//     onMediaControlChanged(conversationId, _micEnabled[conversationId]!, _cameraEnabled[conversationId] ?? true);
//   }

//   Future<void> toggleCamera(int conversationId) async {
//     _cameraEnabled[conversationId] = !(_cameraEnabled[conversationId] ?? true);
//     _localStream?.getVideoTracks().forEach((track) {
//       track.enabled = _cameraEnabled[conversationId]!;
//     });
//     _webSocketService.sendMediaControl(
//       _userId!,
//       conversationId,
//       _micEnabled[conversationId] ?? true,
//       _cameraEnabled[conversationId]!,
//       _userName!,
//     );
//     onMediaControlChanged(conversationId, _micEnabled[conversationId] ?? true, _cameraEnabled[conversationId]!);
//   }

//   Future<void> hangUp(int conversationId) async {
//     _localStream?.getTracks().forEach((track) => track.stop());
//     _remoteStreams[conversationId]?.forEach((stream) => stream.getTracks().forEach((track) => track.stop()));
//     _peerConnections[conversationId]?.forEach((_, peerConnection) => peerConnection.close());
//     _webSocketService.sendLeaveRoom(_userId!, conversationId, _userName!);
//     _localStream = null;
//     _remoteStreams.remove(conversationId);
//     _peerConnections.remove(conversationId);
//     _isRoomCreated.remove(conversationId);
//     _isRoomJoined.remove(conversationId);
//     onRemoteStreamsChanged(conversationId, []);
//   }

//   MediaStream? get localStream => _localStream;
//   List<MediaStream> getRemoteStreams(int conversationId) => _remoteStreams[conversationId] ?? [];
//   bool getMicEnabled(int conversationId) => _micEnabled[conversationId] ?? true;
//   bool getCameraEnabled(int conversationId) => _cameraEnabled[conversationId] ?? true;
// }