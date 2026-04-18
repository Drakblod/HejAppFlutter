import 'package:flutter/material.dart';
import '../../../../core/models/group.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;

  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = _colorFromTheme(group.theme);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.15),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                // Icon Avatar with Gradient Background
                Hero(
                  tag: 'group_icon_${group.id}',
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeColor.withValues(alpha: 0.8),
                          themeColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        group.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                
                // Group Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Joined recently', // Could be dynamic if we had member list count
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _colorFromTheme(String theme) {
    switch (theme.toLowerCase()) {
      case 'green': return const Color(0xFF2E7D32);
      case 'blue': return const Color(0xFF1565C0);
      case 'red': return const Color(0xFFC62828);
      case 'purple': return const Color(0xFF6A1B9A);
      case 'orange': return const Color(0xFFEF6C00);
      default: return const Color(0xFF424242);
    }
  }
}
