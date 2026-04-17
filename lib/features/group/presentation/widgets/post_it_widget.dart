import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/board_item.dart';

class PostItWidget extends StatelessWidget {
  final BoardItem item;

  const PostItWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.backgroundColor,
        borderRadius: BorderRadius.circular(2), // Very slight rounding like a physical note
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
            style: GoogleFonts.kenia(
              fontSize: 20,
              color: item.textColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.author,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
