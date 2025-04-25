import 'dart:io';

import 'package:first_app/PlatformClient/config.dart';
import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/models/attachment.dart';
import 'package:first_app/data/providers/CallProvider.dart';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';
import 'package:first_app/data/repositories/WebRTCService/webRTCService.dart';
import 'package:flutter/material.dart';
import 'package:first_app/data/models/messages.dart';
import 'package:first_app/data/repositories/Message_Repo/message_repository.dart';
import 'package:first_app/data/repositories/Conversations_repo/conversations_repository.dart';
import 'package:first_app/data/repositories/Participants_Repo/participants_repo.dart';
import 'package:first_app/data/models/conversation.dart';
import 'package:first_app/data/models/participants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatProvider with ChangeNotifier {
  final MessageRepo _messageRepo = MessageRepo();
  final ConversationRepo _conversationRepo = ConversationRepo();
  final ParticipantsRepo _participantsRepo = ParticipantsRepo();
  late WebSocketService _webSocketService;

  List<MessageWithAttachment> _messages = [];
  Conversation? _conversation;
  List<Participants> _participants = [];
  final int userId;
  final int conversationId;
  String baseURLWS = Config.baseUrlWS;
  List<MessageWithAttachment> get messages => _messages;
  Conversation? get conversation => _conversation;
  List<Participants> get participants => _participants;

  ChatProvider({required this.userId, required this.conversationId}) {
    _initializeWebSocket();
    _loadData();
  }

  void addMessage(MessageWithAttachment message) {
    _messages.add(message);
    notifyListeners();
  }

  void _initializeWebSocket() {
    _webSocketService = WebSocketService(
      url: baseURLWS,
      onMessageReceived: _onMessageReceived,
    );
    print(
      'Initializing WebSocket for user $userId, conversation $conversationId',
    );
    try {
      _webSocketService.connect(userId, conversationId);
    } catch (e) {
      print('Failed to initialize WebSocket: $e');
    }
  }

  // Future<void> _handleCallButtonPress(BuildContext context, CallProvider callProvider) async {
  //   if (callProvider.isCalling) {
  //     // Kết thúc cuộc gọi
  //     callProvider.endCall();
  //   } else {
  //     // Kiểm tra quyền micro
  //     if (await Permission.microphone.request().isGranted) {
  //       // Bắt đầu cuộc gọi
  //       callProvider.startCall(userId, conversationId);
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Yêu cầu quyền micro bị từ chối')),
  //       );
  //     }
  //   }
  // }

  
  Future<void> _loadData() async {
    print('Loading data for conversation $conversationId and user $userId');
    try {
      final fetchedMessages = await _messageRepo
          .getMessages(conversationId, userId)
          .catchError((e) {
            print('Failed to fetch messages: $e');
            return <MessageWithAttachment>[];
          });

      final fetchedConversation = await _conversationRepo
          .getConversation(conversationId)
          .catchError((e) {
            print('Failed to fetch conversation: $e');
            return null;
          });

      final fetchedParticipants = await _participantsRepo
          .getParticipants(conversationId)
          .catchError((e) {
            print('Failed to fetch participants: $e');
            return <Participants>[];
          });

      _messages = fetchedMessages;
      _conversation = fetchedConversation;
      _participants = fetchedParticipants ?? [];

      // 👉 Gán lại tên nếu không phải group
      if (_conversation != null && !_conversation!.isGroup) {
        print("✅ Checking participants:");
        for (var p in _participants) {
          print("Participant: id=${p.id}, userId=${p.userId}, name=${p.name}");
        }

        final others =
            _participants
                .where((p) => p.userId != 0 && p.userId != userId)
                .toList();

        if (others.isNotEmpty) {
          final other = others.first;
          print(
            "✅ Other participant found: ID=${other.id}, UserID=${other.userId}, Name=${other.name}",
          );
          _conversation!.name = other.name ?? _conversation!.name;
        } else {
          print("❌ No valid other participant found");
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error loading data: $e');
      _messages = [];
      _conversation = null;
      _participants = [];
      notifyListeners();
    }
  }

  Future<void> deleteMessage(int messageId) async {
    await _messageRepo.deleteMessage(messageId);
    print("ok");
    _messages
        .firstWhere((message) => message.message.id == messageId)
        .message
        .isRecalled = true;
    _messages
        .firstWhere((message) => message.message.id == messageId)
        .message
        .content = "Tin nhắn đã được thu hồi";
    notifyListeners();
  }

  void updateConversation(Conversation newConversation) {
    _conversation = newConversation;
    notifyListeners();
  }

  void updateParticipants(List<Participants> newParticipants) {
    _conversation?.participants = newParticipants;
    notifyListeners();
  }

  void _onMessageReceived(MessageWithAttachment messageWithAttachment) {
    if (messageWithAttachment.message.conversationId != conversationId) return;
    print(
      "tin nhắn nhận được: ${messageWithAttachment.message.content}${messageWithAttachment.message.isRecalled}",
    );

    if (messageWithAttachment.message.isRecalled) {
      _messages
          .firstWhere(
            (message) => message.message.id == messageWithAttachment.message.id,
          )
          .message
          .content = "Tin nhắn đã được thu hồi";
      _messages
          .firstWhere(
            (message) => message.message.id == messageWithAttachment.message.id,
          )
          .message
          .isRecalled = true;
      notifyListeners();
      return;
    }

    if (messageWithAttachment.message.type == "system") {
      _messages.add(messageWithAttachment);
      notifyListeners();
      return;
    }
    // Kiểm tra xem tin nhắn đã tồn tại chưa (dựa trên ID)
    bool isDuplicate = _messages.any(
      (msg) => msg.message.id == messageWithAttachment.message.id,
    );
    if (!isDuplicate) {
      _messages.add(messageWithAttachment);
      notifyListeners();
    } else {
      print(
        "Message with ID ${messageWithAttachment.message.id} already exists, skipping.",
      );
    }
  }

  void addMember(int userId, int conversationId) {
    _webSocketService.addMember(userId, conversationId);
    notifyListeners();
  }

  // void sendMessage(String content, XFile? file, int? recipientId) {
  //   if(_conversation?.isGroup ?? false){
  //     sendGroupMessage(content, file);
  //   } else {
  //     sendPrivateMessage(content, recipientId ?? 0, file);
  //   }
  // }

  Future<void> sendGroupMessage(String content, XFile? file) async {
    var isFile = false;
    int? fileID;
    String? fileUrl;
    if (file != null) {
      final uploadResult = await _messageRepo.uploadFile(file);
      fileID = uploadResult['fileId'];
      fileUrl = uploadResult['fileUrl'];
      if (fileID != null && fileUrl != null) {
        isFile = true;

        var newMessage = MessageDTOForAttachment(
          id: DateTime.now().millisecondsSinceEpoch, // ID tạm thời
          senderId: userId,
          content: content,
          createdAt: DateTime.now(),
          conversationId: conversationId,
          isRead: true,
          isFile: isFile ?? false,
          isRecalled: false,
        );
        var attachment = AttachmentDTOForAttachment(
          id: fileID,
          fileUrl: fileUrl,
          fileSize: 1,
          fileType: file.mimeType ?? '',
          uploadedAt: DateTime.now(),
        );
        var messageWithAttachment = MessageWithAttachment(
          message: newMessage,
          attachment: attachment,
        );

        // _messages.add(messageWithAttachment);
        // notifyListeners(); // 🚀 Cập nhật UI ngay
        _webSocketService.sendMessage(userId, conversationId, content, fileID);
        return;
      }
    }

    print('Sending group message: $content');
    final newMessage = MessageDTOForAttachment(
      id: DateTime.now().millisecondsSinceEpoch, // ID tạm thời
      senderId: userId,
      content: content,
      createdAt: DateTime.now(),
      conversationId: conversationId,
      isRead: true,
      isFile: isFile ?? false,
      isRecalled: false,
    );
    var messageWithAttachment = MessageWithAttachment(
      message: newMessage,
      attachment: null,
    );
    //_messages.add(messageWithAttachment);
    // notifyListeners(); // 🚀 Cập nhật UI ngay
    _webSocketService.sendMessage(userId, conversationId, content, fileID);
  }

  Future<void> sendPrivateMessage(
    String content,
    int recipientId,
    XFile? file,
  ) async {
    print('Sending private message to $recipientId: $content');
    late bool isFile = false;
    int? fileID;
    String? fileUrl;
    if (file != null) {
      final uploadResult = await _messageRepo.uploadFile(file);
      fileID = uploadResult['fileId'];
      fileUrl = uploadResult['fileUrl'];
      if (fileID != null) {
        isFile = true;
        var newMessage = MessageDTOForAttachment(
          id: DateTime.now().millisecondsSinceEpoch,
          senderId: userId,
          content: content,
          createdAt: DateTime.now(),
          conversationId: conversationId,
          isRead: true,
          isFile: isFile,
          isRecalled: false,
        );
        var attachment = AttachmentDTOForAttachment(
          id: fileID,
          fileUrl: fileUrl ?? '',
          fileSize: 1,
          fileType: file.mimeType ?? '',
          uploadedAt: DateTime.now(),
        );
        var messageWithAttachment = MessageWithAttachment(
          message: newMessage,
          attachment: attachment,
        );
        // _messages.add(messageWithAttachment);
        // notifyListeners(); // 🚀 Cập nhật UI ngay
        print(fileID);
        //gửi tin nhắn
        _webSocketService.sendPrivateMessage(
          userId,
          conversationId,
          recipientId,
          content,
          fileID,
        );
        return;
      }
    }

    final newMessage = MessageDTOForAttachment(
      id: DateTime.now().millisecondsSinceEpoch,
      senderId: userId,
      content: content,
      createdAt: DateTime.now(),
      conversationId: conversationId,
      isRead: true,
      isFile: isFile,
      isRecalled: false,
    );
    var messageWithAttachment = MessageWithAttachment(
      message: newMessage,
      attachment: null,
    );
    // _messages.add(messageWithAttachment);
    // notifyListeners(); // 🚀 Cập nhật UI ngay
    _webSocketService.sendPrivateMessage(
      userId,
      conversationId,
      recipientId,
      content,
      fileID,
    );
  }

  void disconnect() {
    print('Disconnecting WebSocket');
    _webSocketService.disconnect();
  }
}
