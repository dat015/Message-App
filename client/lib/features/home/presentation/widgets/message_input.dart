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
  bool _showEmojiPicker =
      false; // Thêm biến để điều khiển hiển thị emoji picker
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

  // void _handleSubmittedPrivate(String text) {
  //   if (text.trim().isEmpty && _selectedFile == null) return;
  //   final provider = Provider.of<ChatProvider>(context, listen: false);
  //   provider.sendPrivateMessage(text.trim(), _selectedFile);
  //   _controller.clear();
  //   setState(() {
  //     _isComposing = false;
  //     _selectedFile = null;
  //   });
  // }

  void _handleTextChange(String text) {
    setState(() {
      _isComposing = text.trim().isNotEmpty || _selectedFile != null;
    });
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      _isTextFieldFocused = false; // Ẩn bàn phím khi mở emoji picker
      FocusScope.of(context).unfocus(); // Ẩn bàn phím
    });
  }

  void _onEmojiSelected(Emoji emoji) {
    _controller.text += emoji.emoji;
    _handleTextChange(_controller.text); // Cập nhật trạng thái khi thêm emoji
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
                          onPressed: () {
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
                              color:
                                  _isTextFieldFocused
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
                                  onTap:
                                      () => setState(() {
                                        _isTextFieldFocused = true;
                                        _showEmojiPicker =
                                            false; // Ẩn emoji picker khi nhập
                                      }),
                                  onEditingComplete:
                                      () => setState(() {
                                        _isTextFieldFocused = false;
                                      }),
                                ),
                              ),
                              if (_isComposing)
                                IconButton(
                                  icon: const Icon(
                                    Icons.send,
                                    color: Colors.blue,
                                  ),
                                  onPressed:
                                      () => _handleSubmitted(_controller.text),
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
                                      onPressed:
                                          _toggleEmojiPicker, // Hiển thị emoji picker
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.image,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: _pickFile,
                                    ),
                                    // IconButton(
                                    //   icon: Icon(
                                    //     Icons.person,
                                    //     color: Colors.grey[600],
                                    //   ),
                                    //   onPressed: () {
                                    //     showModalBottomSheet(
                                    //       context: context,
                                    //       builder:
                                    //           (context) => Container(
                                    //             padding: const EdgeInsets.all(
                                    //               16,
                                    //             ),
                                    //             child: Column(
                                    //               mainAxisSize:
                                    //                   MainAxisSize.min,
                                    //               crossAxisAlignment:
                                    //                   CrossAxisAlignment.start,
                                    //               children: [
                                    //                 Text(
                                    //                   'Gửi tin nhắn riêng',
                                    //                   style: TextStyle(
                                    //                     fontSize: 18,
                                    //                     fontWeight:
                                    //                         FontWeight.bold,
                                    //                     color: Colors.grey[800],
                                    //                   ),
                                    //                 ),
                                    //                 const SizedBox(height: 16),
                                    //                 ...provider.participants
                                    //                     .where(
                                    //                       (p) =>
                                    //                           p.userId !=
                                    //                           provider.userId,
                                    //                     )
                                    //                     .map(
                                    //                       (p) => ListTile(
                                    //                         leading: CircleAvatar(
                                    //                           backgroundImage:
                                    //                               NetworkImage(
                                    //                                 'https://ui-avatars.com/api/?name=User+${p.userId}&background=random',
                                    //                               ),
                                    //                         ),
                                    //                         title: Text(
                                    //                           'User ${p.userId}',
                                    //                         ),
                                    //                         onTap: () {
                                    //                           Navigator.pop(
                                    //                             context,
                                    //                           );
                                    //                           if (_controller
                                    //                                   .text
                                    //                                   .trim()
                                    //                                   .isNotEmpty ||
                                    //                               _selectedFile !=
                                    //                                   null) {
                                    //                             provider.sendPrivateMessage(
                                    //                               _controller
                                    //                                   .text
                                    //                                   .trim(),
                                    //                               p.userId,
                                    //                               _selectedFile,
                                    //                             );
                                    //                             _controller
                                    //                                 .clear();
                                    //                             setState(() {
                                    //                               _selectedFile =
                                    //                                   null;
                                    //                               _isComposing =
                                    //                                   false;
                                    //                             });
                                    //                           }
                                    //                         },
                                    //                       ),
                                    //                     )
                                    //                     .toList(),
                                    //               ],
                                    //             ),
                                    //           ),
                                    //     );
                                    //   },
                                    // ),
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
        // Hiển thị Emoji Picker khi _showEmojiPicker = true
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
