class AiCaptionRequest {
  final String prompt;

  AiCaptionRequest({required this.prompt});

  Map<String, dynamic> toJson() => {
        'Prompt': prompt,
      };
}