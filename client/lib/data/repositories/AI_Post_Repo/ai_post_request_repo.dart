import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/models/ai_caption_request.dart';
import 'package:first_app/data/models/ai_caption_response.dart';

class AiCaptionService {
  final ApiClient apiClient;

  AiCaptionService(this.apiClient);

  Future<AiCaptionResponse> generateCaption(String prompt) async {
    final request = AiCaptionRequest(prompt: prompt);
    final response = await apiClient.post(
      '/api/AIPost/generate-custom',
      data: request.toJson(),
    );
    return AiCaptionResponse.fromJson(response);
  }
}