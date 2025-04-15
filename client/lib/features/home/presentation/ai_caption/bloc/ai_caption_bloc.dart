import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:first_app/data/repositories/AI_Post_Repo/ai_post_request_repo.dart';
import 'ai_caption_event.dart';
import 'ai_caption_state.dart';

class AiCaptionBloc extends Bloc<AiCaptionEvent, AiCaptionState> {
  final AiCaptionService service;
  String? _lastPrompt;

  AiCaptionBloc(this.service) : super(AiCaptionInitial()) {
    on<GenerateCaption>((event, emit) async {
      emit(AiCaptionLoading());
        try {
        _lastPrompt = event.prompt;
        final response = await service.generateCaption(event.prompt);
        emit(AiCaptionLoaded(response.result));
      } catch (e) {
        emit(AiCaptionError(e.toString()));
      }
    });

    on<RegenerateCaption>((event, emit) async {
      if (_lastPrompt != null) {
        emit(AiCaptionLoading());
        try {
          final response = await service.generateCaption(_lastPrompt!);
          emit(AiCaptionLoaded(response.result));
        } catch (e) {
          emit(AiCaptionError(e.toString()));
        }
      }
    });
  }
}