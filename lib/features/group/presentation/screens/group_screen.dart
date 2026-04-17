import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/res/app_themes.dart';
import '../../providers/board_providers.dart';
import '../views/bulletin_board_view.dart';
import '../widgets/create_postit_sheet.dart';
import '../../../chat/presentation/views/chat_view.dart';
import '../../../chat/providers/chat_providers.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../core/models/postit.dart';
import '../../providers/postit_providers.dart';

class GroupScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupMetaProvider(widget.groupId));

    return groupAsync.when(
      data: (group) {
        if (group == null) return const Scaffold(body: Center(child: Text('Group not found')));

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5), // General light grey base
          body: Column(
            children: [
              // 1. Header with Background or Gradient
              _buildHeader(group),

              // 2. Main Content
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    BulletinBoardView(groupId: widget.groupId),
                    ChatView(groupId: widget.groupId),
                  ],
                ),
              ),

            ],
          ),
          bottomNavigationBar: _buildGlassBottomBar(),
          extendBody: true,
          floatingActionButton: _currentIndex == 0
              ? FloatingActionButton(
                  backgroundColor: const Color(0xFF2F7D32),
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CreatePostItSheet(groupId: widget.groupId),
                    );
                  },
                )
              : null,
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildGlassBottomBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.95), // Slightly more solid for better readability
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.grid_view_rounded, 'BOARD'),
            _buildNavItem(1, Icons.chat_bubble_rounded, 'CHAT'),
          ],
        ),
      ),
    );
  }

  Future<void> _extractAI(String groupId) async {
    // 1. Fetch recent messages
    final messages = await ref.read(chatMessagesProvider(groupId).future);
    if (messages.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough messages to analyze yet!')));
      return;
    }

    // 2. Call Gemini
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      await ref.read(geminiControllerProvider.notifier).extractFromChat(groupId, messages);
      
      if (mounted) Navigator.pop(context); // Pop loading

      // 3. Show suggestions
      if (mounted) {
        final suggestions = ref.read(geminiControllerProvider);
        suggestions.whenData((list) {
          if (!mounted) return;
          if (list.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new events or takeaways found.')));
          } else {
            _showSuggestionsDialog(list);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Error: $e')));
      }
    }
  }

  void _showSuggestionsDialog(List<PostIt> suggestions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✨ AI Found some Ideas!'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final s = suggestions[index];
              return ListTile(
                leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
                title: Text(s.text),
                subtitle: Text('Color: ${s.textColor}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('DISCARD')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(postItControllerProvider.notifier).saveMultiplePostIts(suggestions);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Board!')));
                setState(() => _currentIndex = 0); // Switch to board
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F7D32), foregroundColor: Colors.white),
            child: const Text('PIN ALL TO BOARD'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(group) {
    final gradient = AppThemes.getGradient(group.theme);
    final hasBg = group.backgroundImage != null && group.backgroundImage!.isNotEmpty;

    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: !hasBg && gradient != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              )
            : null,
        image: hasBg
            ? DecorationImage(
                image: NetworkImage(group.backgroundImage!),
                fit: BoxFit.cover,
              )
            : null,
        color: !hasBg && gradient == null ? const Color(0xFF2F7D32) : null,
      ),
      child: Stack(
        children: [
          // Dark Overlay for readability
          if (hasBg || gradient != null)
            Container(color: Colors.black26),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => context.go('/home'),
                  ),
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (group.ownerId == ref.watch(authRepositoryProvider).currentUser?.uid)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_currentIndex == 1) // Only show on Chat tab
                          IconButton(
                            icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
                            onPressed: () => _extractAI(group.id),
                          ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: Colors.white),
                          onPressed: () => context.push('/group/${widget.groupId}/admin'),
                        ),
                      ],
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white60,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}
