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
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gợi ý Caption bằng AI',
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenWidth * 0.03),
          TextField(
            controller: _promptController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Ví dụ: "Một ngày nắng đẹp tại biển"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenWidth * 0.03,
              ),
            ),
            maxLines: 2,
          ),
          SizedBox(height: screenWidth * 0.03),
          ElevatedButton(
            onPressed: _promptController.text.isNotEmpty
                ? () {
                    context.read<AiCaptionBloc>().add(GenerateCaption(prompt: _promptController.text));
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
              minimumSize: Size(double.infinity, 0),
            ),
            child: Text(
              'Tạo Caption',
              style: TextStyle(fontSize: screenWidth * 0.04),
            ),
          ),
          SizedBox(height: screenWidth * 0.03),
          Expanded(
            child: BlocBuilder<AiCaptionBloc, AiCaptionState>(
              builder: (context, state) {
                if (state is AiCaptionLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is AiCaptionLoaded) {
                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              child: Text(
                                state.caption,
                                style: TextStyle(fontSize: screenWidth * 0.04),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.03),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                context.read<AiCaptionBloc>().add(RegenerateCaption());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Tái tạo'),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                widget.onCaptionSelected(state.caption);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Sử dụng'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else if (state is AiCaptionError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lỗi: ${state.message}',
                          style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.04),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: screenWidth * 0.03),
                        ElevatedButton(
                          onPressed: () {
                            if (_promptController.text.isNotEmpty) {
                              context
                                  .read<AiCaptionBloc>()
                                  .add(GenerateCaption(prompt: _promptController.text));
                            }
                          },
                          child: Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                return Center(
                  child: Text(
                    'Nhập ý tưởng để tạo caption!',
                    style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}