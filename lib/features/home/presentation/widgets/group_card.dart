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
    final themeColor = _groupColor(group);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.12),
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8E2)),
            ),
            child: Row(
              children: [
                // Icon Avatar with Gradient Background
                Hero(
                  tag: 'group_icon_${group.id}',
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeColor.withValues(alpha: 0.8),
                          themeColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
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
                        _moduleSummary(group.enabledModules),
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
                  Icons.arrow_forward_rounded,
                  size: 21,
                  color: themeColor.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _groupColor(Group group) {
    final parsed = int.tryParse(group.baseColor);
    if (parsed != null) return Color(parsed);
    return _colorFromTheme(group.theme);
  }

  String _moduleSummary(Map<String, bool> modules) {
    final count = modules.values.where((enabled) => enabled).length;
    return '$count ${count == 1 ? 'module' : 'modules'} enabled';
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
