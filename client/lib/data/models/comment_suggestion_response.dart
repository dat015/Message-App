class CommentSuggestionResponse {
  final List<String> suggestions;

  CommentSuggestionResponse({required this.suggestions});

  factory CommentSuggestionResponse.fromJson(Map<String, dynamic> json) {
    print('CommentSuggestionResponse: Parsing JSON - $json');
    List<String> suggestions = [];
    
    try {
      // Trường hợp 1: suggestions là Map chứa $values
      if (json['suggestions'] is Map) {
        suggestions = (json['suggestions']['\$values'] as List<dynamic>?)?.cast<String>() ?? [];
      }
      // Trường hợp 2: suggestions là List trực tiếp
      else if (json['suggestions'] is List) {
        suggestions = (json['suggestions'] as List<dynamic>).cast<String>();
      }
    } catch (e) {
      print('CommentSuggestionResponse: Parsing error - $e');
    }
    
    return CommentSuggestionResponse(suggestions: suggestions);
  }
}