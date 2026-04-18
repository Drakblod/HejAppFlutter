import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/postit_providers.dart';

class CreatePostItSheet extends ConsumerStatefulWidget {
  final String groupId;

  const CreatePostItSheet({super.key, required this.groupId});

  @override
  ConsumerState<CreatePostItSheet> createState() => _CreatePostItSheetState();
}

class _CreatePostItSheetState extends ConsumerState<CreatePostItSheet> {
  final _textController = TextEditingController();
  String _selectedColor = 'yellow';

  final List<Map<String, dynamic>> _colors = [
    {'name': 'yellow', 'color': const Color(0xFFFFF9C4)},
    {'name': 'cyan', 'color': const Color(0xFFB2EBF2)},
    {'name': 'lime', 'color': const Color(0xFFF0F4C3)},
    {'name': 'pink', 'color': const Color(0xFFF8BBD0)},
    {'name': 'orange', 'color': const Color(0xFFFFE0B2)},
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'New Post-It',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _textController,
            autofocus: true,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Write something delightful...',
              filled: true,
              fillColor: _colors.firstWhere((c) => c['name'] == _selectedColor)['color'],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Pick a color:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _colors.map((c) {
              final isSelected = _selectedColor == c['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c['name']),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c['color'],
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (_textController.text.trim().isEmpty) return;
              
              final navigator = Navigator.of(context);
              
              await ref.read(postItControllerProvider.notifier).savePostIt(
                groupId: widget.groupId,
                text: _textController.text.trim(),
                textColor: _selectedColor,
              );
              
              if (!mounted) return;
              navigator.pop();
            },
            child: const Text('Pin to Board', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
