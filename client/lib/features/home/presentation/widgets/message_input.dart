import 'dart:io';

import 'package:first_app/data/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:io' show Platform;

class MessageInput extends StatefulWidget {
  const MessageInput({super.key});

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isTextFieldFocused = false;
  bool _isComposing = false;
  bool _showEmojiPicker = false;
  XFile? _selectedFile;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = pickedFile;
          _isComposing = true;
        });
        _handleSubmitted("FILE");
      }
    } catch (e) {
      print("Error picking file: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
        );
      }
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty && _selectedFile == null) return;
    final provider = Provider.of<ChatProvider>(context, listen: false);
    provider.sendGroupMessage(text.trim(), _selectedFile);
    _controller.clear();
    setState(() {
      _isComposing = false;
      _selectedFile = null;
    });
  }

  void _handleTextChange(String text) {
    setState(() {
      _isComposing = text.trim().isNotEmpty || _selectedFile != null;
    });
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      _isTextFieldFocused = false;
      FocusScope.of(context).unfocus();
    });
  }

  void _onEmojiSelected(Emoji emoji) {
    _controller.text += emoji.emoji;
    _handleTextChange(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedFile != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attach_file, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedFile!.name,
                            style: TextStyle(color: Colors.blue),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey[600]),
                          onPressed: provider.isUploading
                              ? null
                              : () {
                                  setState(() {
                                    _selectedFile = null;
                                    _isComposing = false;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _isTextFieldFocused
                                  ? Colors.blue
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  decoration: const InputDecoration(
                                    hintText: 'Nhập tin nhắn...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  onChanged: _handleTextChange,
                                  onTap: () => setState(() {
                                    _isTextFieldFocused = true;
                                    _showEmojiPicker = false;
                                  }),
                                  onEditingComplete: () => setState(() {
                                    _isTextFieldFocused = false;
                                  }),
                                ),
                              ),
                              if (_isComposing)
                                provider.isUploading
                                    ? const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.send,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () =>
                                            _handleSubmitted(_controller.text),
                                      )
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.emoji_emotions_outlined,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: provider.isUploading
                                          ? null
                                          : _toggleEmojiPicker,
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.image,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed:
                                          provider.isUploading ? null : _pickFile,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) => _onEmojiSelected(emoji),
              config: Config(
                height: 250,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  columns: 7,
                  backgroundColor: const Color(0xFFF2F2F2),
                  buttonMode: ButtonMode.MATERIAL,
                ),
                skinToneConfig: const SkinToneConfig(
                  enabled: true,
                  dialogBackgroundColor: Colors.white,
                  indicatorColor: Colors.grey,
                ),
                categoryViewConfig: CategoryViewConfig(
                  backgroundColor: const Color(0xFFF2F2F2),
                  iconColor: Colors.grey,
                  iconColorSelected: Colors.blue,
                  backspaceColor: Colors.blue,
                ),
                searchViewConfig: const SearchViewConfig(
                  backgroundColor: Color(0xFFF2F2F2),
                  buttonIconColor: Colors.blue,
                ),
              ),
            ),
          ),
      ],
    );
  }
}