class OTPsResponse {
  final String otpCode;
  final String message;
  final bool success;

  OTPsResponse({
    required this.otpCode,
    required this.message,
    required this.success,
  });

  factory OTPsResponse.fromJson(Map<String, dynamic> json) {
    return OTPsResponse(
      otpCode: json['OTPCode'] ?? '',
      message: json['message'] ?? '',
      success: json['success'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'OTPCode': otpCode,
      'message': message,
      'success': success,
    };
  }
}