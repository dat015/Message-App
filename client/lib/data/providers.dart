import 'dart:io';

import 'package:first_app/PlatformClient/config.dart';
import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/models/attachment.dart';
import 'package:flutter/material.dart';
import 'package:first_app/data/models/messages.dart';
import 'package:first_app/data/repositories/Chat/websocket_service.dart';
import 'package:first_app/data/repositories/Message_Repo/message_repository.dart';
import 'package:first_app/data/repositories/Conversations_repo/conversations_repository.dart';
import 'package:first_app/data/repositories/Participants_Repo/participants_repo.dart';
import 'package:first_app/data/models/conversation.dart';
import 'package:first_app/data/models/participants.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<void> _loadData() async {
    print('Loading data for conversation $conversationId and user $userId');
    try {
      final fetchedMessages = await _messageRepo
          .getMessages(conversationId)
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
      notifyListeners();
    } catch (e) {
      print('Error loading data: $e');
      _messages = [];
      _conversation = null;
      _participants = [];
      notifyListeners();
    }
  }

  void _onMessageReceived(MessageWithAttachment messageWithAttachment) {
    if (messageWithAttachment.message.conversationId != conversationId) return;

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

        _messages.add(messageWithAttachment);
        notifyListeners(); // 🚀 Cập nhật UI ngay
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
    );
    var messageWithAttachment = MessageWithAttachment(
      message: newMessage,
      attachment: null,
    );
    _messages.add(messageWithAttachment);
    notifyListeners(); // 🚀 Cập nhật UI ngay
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
        _messages.add(messageWithAttachment);
        notifyListeners(); // 🚀 Cập nhật UI ngay
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
    );
    var messageWithAttachment = MessageWithAttachment(
      message: newMessage,
      attachment: null,
    );
    _messages.add(messageWithAttachment);
    notifyListeners(); // 🚀 Cập nhật UI ngay
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
