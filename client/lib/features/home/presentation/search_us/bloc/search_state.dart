class SearchUsersState {
  final List<dynamic> searchResults;
  final bool isWebSocketConnected;

  SearchUsersState({
    required this.searchResults,
    this.isWebSocketConnected = false,
  });

  SearchUsersState copyWith({
    List<dynamic>? searchResults,
    bool? isWebSocketConnected,
  }) {
    return SearchUsersState(
      searchResults: searchResults ?? this.searchResults,
      isWebSocketConnected: isWebSocketConnected ?? this.isWebSocketConnected,
    );
  }
}