import 'package:flutter/material.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/postit.dart';

enum BoardItemType { chat, postit }

class BoardItem {
  final String id;
  final BoardItemType type;
  final String text;
  final String author;
  final int ts;
  final Color backgroundColor;
  final Color textColor;

  BoardItem({
    required this.id,
    required this.type,
    required this.text,
    required this.author,
    required this.ts,
    required this.backgroundColor,
    required this.textColor,
  });

  factory BoardItem.fromMessage(ChatMessage m) {
    String display = m.text;
    if (display.isEmpty && m.photoUrl != null) display = '[Photo]';
    if (display.length > 50) display = '${display.substring(0, 47)}...';

    return BoardItem(
      id: m.id,
      type: BoardItemType.chat,
      text: display,
      author: m.senderName,
      ts: m.ts,
      backgroundColor: const Color(0xFFAEE1FF), // Blue like MAUI mock
      textColor: Colors.black,
    );
  }

  factory BoardItem.fromPostIt(PostIt p) {
    return BoardItem(
      id: p.id,
      type: BoardItemType.postit,
      text: p.text,
      author: 'member', // Could resolve later
      ts: p.ts,
      backgroundColor: const Color(0xFFFFFB97), // Yellow Post-It color
      textColor: _parseColor(p.textColor),
    );
  }

  static Color _parseColor(String color) {
    switch (color.toLowerCase()) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'white': return Colors.white;
      case 'black': return Colors.black;
      default:
        if (color.startsWith('#')) {
          try {
            return Color(int.parse(color.replaceFirst('#', '0xFF')));
          } catch (_) {}
        }
        return Colors.black;
    }
  }
}
