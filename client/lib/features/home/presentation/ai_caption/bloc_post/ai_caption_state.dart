abstract class AiCaptionState {}

class AiCaptionInitial extends AiCaptionState {}

class AiCaptionLoading extends AiCaptionState {}

class AiCaptionLoaded extends AiCaptionState {
  final String caption;

  AiCaptionLoaded(this.caption);
}

class AiCaptionError extends AiCaptionState {
  final String message;

  AiCaptionError(this.message);
}