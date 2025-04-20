import 'package:first_app/data/repositories/AI_Post_Repo/comment_suggestion_repo.dart';
import 'package:first_app/features/home/presentation/ai_caption/bloc_comments/comment_suggestion_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'comment_suggestion_event.dart';
import 'comment_suggestion_state.dart';

class CommentSuggestionBloc
    extends Bloc<CommentSuggestionEvent, CommentSuggestionState> {
  final CommentSuggestionService repo;

  CommentSuggestionBloc(this.repo) : super(CommentSuggestionInitial()) {
    on<GenerateCommentSuggestions>((event, emit) async {
      print('CommentSuggestionBloc: Event received - postContent: ${event.postContent}, imageUrl: ${event.imageUrl}');
      emit(CommentSuggestionLoading());
      try {
        final response = await repo.generateSuggestions(
          event.postContent,
          event.imageUrl,
        );
        print('CommentSuggestionBloc: Suggestions loaded - ${response.suggestions}');
        emit(CommentSuggestionLoaded(response.suggestions));
      } catch (e, stackTrace) {
        print('CommentSuggestionBloc: Error - $e');
        print('CommentSuggestionBloc: StackTrace - $stackTrace');
        emit(CommentSuggestionError(e.toString()));
      }
    });
  }
}