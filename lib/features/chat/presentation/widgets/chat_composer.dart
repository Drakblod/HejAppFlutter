
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/chat_providers.dart';
import '../../../group/providers/board_providers.dart';

class ChatComposer extends ConsumerStatefulWidget {
  final String groupId;

  const ChatComposer({super.key, required this.groupId});

  @override
  ConsumerState<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends ConsumerState<ChatComposer> {
  final _textController = TextEditingController();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    await ref.read(chatControllerProvider.notifier).sendTextMessage(
      groupId: widget.groupId,
      text: text,
    );
  }

  void _onPickPhoto() async {
    final xFile = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (xFile == null) return;

    final bytes = await xFile.readAsBytes();
    await ref.read(chatControllerProvider.notifier).sendPhotoMessage(
      groupId: widget.groupId,
      bytes: bytes,
      fileName: xFile.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupMetaProvider(widget.groupId));
    
    // Default green if loading or error
    final themeColor = groupAsync.maybeWhen(
      data: (g) => const Color(0xFF2E7D32), 
      orElse: () => const Color(0xFF2E7D32),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: themeColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
            onPressed: _onPickPhoto,
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Write a message...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _onSend(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: Colors.white),
            onPressed: _onSend,
          ),
        ],
      ),
    );
  }
}
