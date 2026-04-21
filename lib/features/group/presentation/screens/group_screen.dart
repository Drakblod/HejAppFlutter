import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/res/app_themes.dart';
import '../../providers/board_providers.dart';
import '../views/bulletin_board_view.dart';
import '../widgets/create_postit_sheet.dart';
import '../../../chat/presentation/views/chat_view.dart';
import '../../../chat/providers/chat_providers.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../core/models/postit.dart';
import '../../providers/postit_providers.dart';
import '../../providers/ai_providers.dart';
import '../widgets/members_list_sheet.dart';
import '../views/files_view.dart';

class GroupScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _showSplash = true;
  bool _splashGone = false;
  late AnimationController _splashController;
  late Animation<double> _bgScaleAnimation;

  @override
  void initState() {
    super.initState();
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _bgScaleAnimation = Tween<double>(begin: 1.2, end: 1.0).animate(
      CurvedAnimation(parent: _splashController, curve: Curves.easeOutCubic),
    );

    _splashController.forward();

    // Hide splash after 2 seconds
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupMetaProvider(widget.groupId));

    return groupAsync.when(
      data: (group) {
        if (group == null) return const Scaffold(body: Center(child: Text('Group not found')));

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: Stack(
            children: [
              // 1. Content Area (Header + Main Views)
              Column(
                children: [
                  _buildHeader(group),
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: [
                        BulletinBoardView(groupId: widget.groupId),
                        ChatView(groupId: widget.groupId),
                        FilesView(groupId: widget.groupId),
                      ],
                    ),
                  ),
                ],
              ),

              // 2. Bottom Navigation (Floating)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildGlassBottomBar(group),
              ),

              // 3. FAB (Only on Board)
              if (_currentIndex == 0)
                Positioned(
                  bottom: 90,
                  right: 16,
                  child: FloatingActionButton(
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
                  ),
                ),

              // 4. Welcome Splash Layer
              if (!_splashGone)
                IgnorePointer(
                  ignoring: !_showSplash,
                  child: AnimatedOpacity(
                    opacity: _showSplash ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    onEnd: () => setState(() => _splashGone = true),
                    child: _buildSplashLayer(group),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildGlassBottomBar(dynamic group) {
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
            _buildNavItem(0, Icons.grid_view_rounded, group.boardLabel ?? 'BOARD', group.fontFamily),
            _buildNavItem(1, Icons.chat_bubble_rounded, group.chatLabel ?? 'CHAT', group.fontFamily),
            _buildNavItem(2, Icons.folder_shared_rounded, group.filesLabel ?? 'FILES', group.fontFamily),
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
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              
              await ref.read(postItControllerProvider.notifier).saveMultiplePostIts(suggestions);
              
              if (mounted) {
                navigator.pop();
                messenger.showSnackBar(const SnackBar(content: Text('Added to Board!')));
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
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 16),
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
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'group_icon_${group.id}',
                          child: Text(
                            group.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => MembersListSheet(groupId: widget.groupId),
                              );
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  group.name,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.getFont(
                                    group.fontFamily ?? 'Outfit',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'View Members',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add_outlined, color: Colors.white70),
                    tooltip: 'Invite Members',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Invite to Group'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Share this code with your friends so they can join this group:'),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        widget.groupId,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.content_copy, size: 20),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: widget.groupId));
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID copied!')));
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
                          ],
                        ),
                      );
                    },
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
                    const SizedBox(width: 48), // Spacer to keep title centered
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, String? fontFamily) {
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
            style: GoogleFonts.getFont(
              fontFamily ?? 'Outfit',
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplashLayer(dynamic group) {
    final hasBg = group.backgroundImage != null && group.backgroundImage!.isNotEmpty;
    final gradient = AppThemes.getGradient(group.theme);

    return Stack(
      children: [
        // Background with Zoom Effect
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _bgScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _bgScaleAnimation.value,
                child: Container(
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
                ),
              );
            },
          ),
        ),

        // Glass Overlay
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),
        ),

        // Welcome Content
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.white70,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  group.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.getFont(
                    group.fontFamily ?? 'Outfit',
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                    shadows: [
                      Shadow(
                        blurRadius: 30,
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
