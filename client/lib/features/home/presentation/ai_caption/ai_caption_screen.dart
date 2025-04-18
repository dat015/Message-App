import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../ai_caption/bloc/ai_caption_bloc.dart';
import '../ai_caption/bloc/ai_caption_event.dart';
import '../ai_caption/bloc/ai_caption_state.dart';

class AiCaptionBottomSheet extends StatefulWidget {
  final Function(String) onCaptionSelected;

  const AiCaptionBottomSheet({Key? key, required this.onCaptionSelected}) : super(key: key);

  @override
  _AiCaptionBottomSheetState createState() => _AiCaptionBottomSheetState();
}

class _AiCaptionBottomSheetState extends State<AiCaptionBottomSheet> {
  final TextEditingController _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      constraints: BoxConstraints(
        maxHeight: size.height * 0.7,
        minHeight: size.height * 0.4,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title with icon
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Gợi ý Caption bằng AI',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Prompt input field
          TextField(
            controller: _promptController,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Ví dụ: "Một ngày nắng đẹp tại biển"',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Icon(
                Icons.edit_note,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              suffixIcon: _promptController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _promptController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            maxLines: 2,
          ),
          
          const SizedBox(height: 16),
          
          // Generate caption button
          ElevatedButton(
            onPressed: _promptController.text.isNotEmpty
                ? () {
                    context.read<AiCaptionBloc>().add(GenerateCaption(prompt: _promptController.text));
                    FocusScope.of(context).unfocus();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
              disabledForegroundColor: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.psychology, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tạo Caption',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Results area
          Expanded(
            child: BlocBuilder<AiCaptionBloc, AiCaptionState>(
              builder: (context, state) {
                if (state is AiCaptionLoading) {
                  return _buildLoadingState();
                } else if (state is AiCaptionLoaded) {
                  return _buildLoadedState(context, state, isDarkMode, colorScheme);
                } else if (state is AiCaptionError) {
                  return _buildErrorState(context, state, isDarkMode);
                }
                return _buildInitialState(isDarkMode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Đang tạo caption...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, AiCaptionLoaded state, bool isDarkMode, ColorScheme colorScheme) {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Caption đề xuất:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.caption,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<AiCaptionBloc>().add(RegenerateCaption());
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  'Tạo lại',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onCaptionSelected(state.caption);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check, size: 18),
                label: Text(
                  'Sử dụng',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, AiCaptionError state, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Đã xảy ra lỗi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (_promptController.text.isNotEmpty) {
                context.read<AiCaptionBloc>().add(GenerateCaption(prompt: _promptController.text));
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nhập ý tưởng để tạo caption!',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI sẽ gợi ý caption phù hợp với ý tưởng của bạn',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}