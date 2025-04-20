abstract class AiCaptionEvent {}

class GenerateCaption extends AiCaptionEvent {
  final String prompt;

  GenerateCaption({required this.prompt});
}

class RegenerateCaption extends AiCaptionEvent {}