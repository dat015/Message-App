abstract class CommentSuggestionEvent {}

class GenerateCommentSuggestions extends CommentSuggestionEvent {
  final String postContent;
  final String? imageUrl;

  GenerateCommentSuggestions({required this.postContent, this.imageUrl});
}