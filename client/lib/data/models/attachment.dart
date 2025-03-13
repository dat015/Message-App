class Attachment {
  int? id; // Có thể null vì trong C# nó là auto-increment
  String fileUrl;
  double fileSize; // Sử dụng double thay cho float trong Dart
  String fileType;
  DateTime uploadedAt;

  // Constructor với các thuộc tính bắt buộc và giá trị mặc định cho uploadedAt
  Attachment({
    this.id,
    required this.fileUrl,
    required this.fileSize,
    required this.fileType,
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  // Factory constructor để tạo từ JSON (nếu cần kết nối API)
  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as int?,
      fileUrl: json['file_url'] as String,
      fileSize: (json['FileSize'] as num).toDouble(),
      fileType: json['file_type'] as String,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }

  // Chuyển đối tượng thành JSON (nếu cần gửi qua API/WebSocket)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_url': fileUrl,
      'FileSize': fileSize,
      'file_type': fileType,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  // Validation cơ bản dựa trên các ràng buộc trong C#
  bool validate() {
    // Kiểm tra file_url: độ dài từ 1 đến 255 ký tự
    if (fileUrl.isEmpty || fileUrl.length > 255) {
      print('Validation failed: file_url must be between 1 and 255 characters');
      return false;
    }

    // Kiểm tra fileSize: từ 0.01 đến 49.99 MB
    if (fileSize < 0.01 || fileSize > 49.99) {
      print('Validation failed: FileSize must be between 0.01 and 49.99 MB');
      return false;
    }

    // Kiểm tra file_type: tối đa 50 ký tự
    if (fileType.isEmpty || fileType.length > 50) {
      print('Validation failed: file_type must be between 1 and 50 characters');
      return false;
    }

    return true;
  }

  // Override toString để dễ debug
  @override
  String toString() {
    return 'Attachment(id: $id, fileUrl: $fileUrl, fileSize: $fileSize, fileType: $fileType, uploadedAt: $uploadedAt)';
  }
}

// Ví dụ sử dụng
void main() {
  // Tạo một Attachment instance
  final attachment = Attachment(
    fileUrl: 'https://example.com/file.pdf',
    fileSize: 5.25,
    fileType: 'application/pdf',
  );

  // Validate
  if (attachment.validate()) {
    print('Attachment is valid: $attachment');
  }

  // Chuyển sang JSON
  final json = attachment.toJson();
  print('JSON: $json');

  // Tạo từ JSON
  final fromJson = Attachment.fromJson(json);
  print('From JSON: $fromJson');
}