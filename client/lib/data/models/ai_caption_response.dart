class AiCaptionResponse {
  final String result;

  AiCaptionResponse({required this.result});

  factory AiCaptionResponse.fromJson(Map<String, dynamic> json) {
    return AiCaptionResponse(
      result: json['result'] ?? '',
    );
  }
}