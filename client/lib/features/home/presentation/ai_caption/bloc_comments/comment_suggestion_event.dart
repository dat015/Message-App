abstract class CommentSuggestionState {}

class CommentSuggestionInitial extends CommentSuggestionState {}

class CommentSuggestionLoading extends CommentSuggestionState {}

class CommentSuggestionLoaded extends CommentSuggestionState {
  final List<String> suggestions;

  CommentSuggestionLoaded(this.suggestions);
}

class CommentSuggestionError extends CommentSuggestionState {
  final String message;

  CommentSuggestionError(this.message);
}