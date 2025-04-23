import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/models/comment_suggestion_request.dart';
import 'package:first_app/data/models/comment_suggestion_response.dart';

class CommentSuggestionService {
  final ApiClient apiClient;

  CommentSuggestionService(this.apiClient);

  Future<CommentSuggestionResponse> generateSuggestions(
      String postContent, String? imageUrl) async {
    final request = CommentSuggestionRequest(
      postContent: postContent,
      imageUrl: imageUrl,
    );
    print('CommentSuggestionService: Sending request - postContent: "$postContent", imageUrl: $imageUrl');
    try {
      final response = await apiClient.post(
        '/api/AIPost/generate-comment-suggestions',
        data: request.toJson(),
      );
      print('CommentSuggestionService: API response type - ${response.runtimeType}');
      print('CommentSuggestionService: API response - $response');
      return CommentSuggestionResponse.fromJson(response);
    } catch (e, stackTrace) {
      print('CommentSuggestionService: Error - $e');
      print('CommentSuggestionService: StackTrace - $stackTrace');
      rethrow;
    }
  }
}