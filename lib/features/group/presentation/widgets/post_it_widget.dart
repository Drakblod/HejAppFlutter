import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/board_item.dart';
import '../../../profile/providers/profile_providers.dart';

class PostItWidget extends ConsumerWidget {
  final BoardItem item;
  final String? fontFamily;
  final VoidCallback? onDelete;

  const PostItWidget({
    super.key,
    required this.item,
    this.fontFamily,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dynamically resolve author name
    final authorAsync = ref.watch(userProfileProvider(item.senderId));

    return GestureDetector(
      onLongPress: onDelete != null
          ? () => _showDeleteConfirmation(context)
          : null,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: item.backgroundColor,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.getFont(
                    fontFamily ?? 'Kenia',
                    fontSize: 20,
                    color: item.textColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                authorAsync.when(
                  data: (profile) => Text(
                    profile?.username ?? item.author,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => Text(
                    item.author,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 10, color: Colors.black54, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _showDeleteConfirmation(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      topRight: Radius.circular(2),
                    ),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post-it?'),
        content: const Text('Are you sure you want to remove this note from the board?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
