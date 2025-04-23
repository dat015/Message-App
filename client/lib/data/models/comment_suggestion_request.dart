class CommentSuggestionRequest {
  final String postContent;
  final String? imageUrl;

  CommentSuggestionRequest({required this.postContent, this.imageUrl});

  Map<String, dynamic> toJson() => {
        'postContent': postContent,
        'imageUrl': imageUrl,
      };
}