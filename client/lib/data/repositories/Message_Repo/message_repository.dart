import 'package:dio/dio.dart';
import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/dto/AttachmentDTO.dart';
import 'package:first_app/data/dto/message_response.dart';
import 'package:first_app/data/models/messages.dart';
import 'package:image_picker/image_picker.dart';

import '../Chat/websocket_service.dart';

class MessageRepo {
  var api_client = ApiClient();
  Future<List<MessageWithAttachment>> getMessages(int conversationId) async {
    try {
      final response = await api_client.get(
        '/api/Message/getMessages/$conversationId',
      );
      print("Response: $response"); // Debug

      List<MessageWithAttachment> messagesWithAttachments = [];

      // ✅ Sửa chỗ này: lấy response['\$values'] để parse
      if (response != null &&
          response is Map<String, dynamic> &&
          response[r'$values'] is List) {
        final values = response[r'$values'] as List;

        messagesWithAttachments =
            values
                .where((json) => json != null)
                .map(
                  (json) => MessageWithAttachment.fromJson(
                    json as Map<String, dynamic>,
                  ),
                )
                .toList();
      } else {
        print("Unexpected response format: $response");
      }

      // Sắp xếp theo thời gian tạo
      messagesWithAttachments.sort(
        (a, b) => a.message.createdAt.compareTo(b.message.createdAt),
      );

      return messagesWithAttachments;
    } catch (e, stacktrace) {
      print("Error fetching messages: $e");
      print("Stacktrace: $stacktrace");
      throw Exception('Failed to fetch messages: $e');
    }
  }

  Future<Map<String, dynamic>> uploadFile(XFile? file) async {
    if (file == null) {
      return {'fileId': 0, 'fileUrl': ''};
    }

    try {
      String fileName = file.path.split('/').last;

      // Tạo FormData để gửi file
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      // Gửi request lên API
      var response = await api_client.post(
        '/api/Message/uploadFile', // Endpoint API
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      // Kiểm tra response và lấy fileId, fileUrl
      if (response != null &&
          response['fileID'] != null &&
          response['fileUrl'] != null) {
        int fileId = response['fileID']; // Lấy ID của file từ API
        String fileUrl = response['fileUrl']; // Lấy URL của file từ API
        print("Upload success: File ID = $fileId, File URL = $fileUrl");
        return {'fileId': fileId, 'fileUrl': fileUrl};
      } else {
        print("Upload failed: $response");
        return {'fileId': 0, 'fileUrl': ''};
      }
    } catch (e) {
      print("Error uploading file: $e");
      return {'fileId': 0, 'fileUrl': ''};
    }
  }

  Future<List<MessageWithAttachment>> searchMessages(
    int conversationId,
    String query,
  ) async {
    try {
      final response = await api_client.get(
        '/api/Message/searchMessages/$conversationId/$query',
      );
      if (response is List<MessageWithAttachment>) {
        return response;
      }
      throw Exception('Failed to search messages');
    } catch (e) {
      throw Exception('Failed to search messages');
    }
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      final response = await api_client.put(
        '/api/Message/recall_message/$messageId',
      );
      // Kiểm tra phản hồi từ API nếu cần
      if (response['success'] != true) {
        throw Exception(
          'Failed to recall message: ${response['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      // Truyền lỗi chi tiết từ ApiClient
      rethrow; // Ném lại lỗi để tầng trên xử lý
    }
  }
}
