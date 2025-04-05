class AttachmentDTO {
  String fileUrl;  // file_url trong C#
  double fileSize; // FileSize trong C#
  String fileType; // file_type trong C#

  // Constructor
  AttachmentDTO({
    required this.fileUrl,
    required this.fileSize,
    required this.fileType,
  });

  // Hàm từ JSON (nếu bạn cần chuyển đổi từ JSON)
  factory AttachmentDTO.fromJson(Map<String, dynamic> json) {
    return AttachmentDTO(
      fileUrl: json['file_url'],
      fileSize: json['FileSize'].toDouble(), // Chuyển đổi thành double
      fileType: json['file_type'],
    );
  }

  // Hàm chuyển thành JSON (nếu bạn cần chuyển đổi sang JSON)
  Map<String, dynamic> toJson() {
    return {
      'file_url': fileUrl,
      'FileSize': fileSize,
      'file_type': fileType,
    };
  }
}
