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
    await ref
        .read(chatControllerProvider.notifier)
        .sendTextMessage(groupId: widget.groupId, text: text);
  }

  void _onPickPhoto() async {
    final xFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (xFile == null) return;

    final bytes = await xFile.readAsBytes();
    await ref
        .read(chatControllerProvider.notifier)
        .sendPhotoMessage(
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
      data: (g) => g == null
          ? const Color(0xFF2E7D32)
          : Color(int.tryParse(g.baseColor) ?? 0xFF2E7D32),
      orElse: () => const Color(0xFF2E7D32),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE4DC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Add photo',
            icon: const Icon(
              Icons.add_photo_alternate_outlined,
              color: Color(0xFF5E6B60),
            ),
            onPressed: _onPickPhoto,
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Color(0xFF1C211D)),
              decoration: const InputDecoration(
                hintText: 'Write a message...',
                hintStyle: TextStyle(color: Colors.black38),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 13,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _onSend(),
            ),
          ),
          IconButton.filled(
            tooltip: 'Send message',
            style: IconButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.arrow_upward_rounded, size: 21),
            onPressed: _onSend,
          ),
        ],
      ),
    );
  }
}
