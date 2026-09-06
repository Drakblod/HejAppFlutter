import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/res/app_themes.dart';
import '../../../../core/widgets/living_background.dart';
import '../../providers/board_providers.dart';
import '../views/bulletin_board_view.dart';
import '../widgets/create_postit_sheet.dart';
import '../../../chat/presentation/views/chat_view.dart';
import '../../../chat/presentation/widgets/direct_chats_sheet.dart';
import '../../../chat/providers/chat_providers.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../core/models/postit.dart';
import '../../providers/postit_providers.dart';
import '../../providers/ai_providers.dart';
import '../widgets/members_list_sheet.dart';
import '../views/files_view.dart';
import '../views/calendar_view.dart';
import '../views/ocr_view.dart';
import '../views/gallery_view.dart';
import '../../providers/meeting_providers.dart';

class GroupScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen>
    with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 700),
    );

    _bgScaleAnimation = Tween<double>(begin: 1.2, end: 1.0).animate(
      CurvedAnimation(parent: _splashController, curve: Curves.easeOutCubic),
    );

    _splashController.forward();

    // Keep the branded transition brief so returning users reach content fast.
    Timer(const Duration(milliseconds: 900), () {
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
        if (group == null) {
          return const Scaffold(body: Center(child: Text('Group not found')));
        }

        // Define all possible modules
        final List<Map<String, dynamic>> allModules = [
          {
            'id': 'board',
            'icon': Icons.grid_view_rounded,
            'label': group.boardLabel ?? 'BOARD',
            'view': BulletinBoardView(groupId: widget.groupId),
          },
          {
            'id': 'chat',
            'icon': Icons.chat_bubble_rounded,
            'label': group.chatLabel ?? 'CHAT',
            'view': ChatView(groupId: widget.groupId),
          },
          {
            'id': 'files',
            'icon': Icons.folder_shared_rounded,
            'label': group.filesLabel ?? 'FILES',
            'view': FilesView(groupId: widget.groupId),
          },
          {
            'id': 'calendar',
            'icon': Icons.calendar_today_rounded,
            'label': 'CALENDAR',
            'view': CalendarView(groupId: widget.groupId),
          },
          {
            'id': 'ocr',
            'icon': Icons.numbers_rounded,
            'label': group.ocrLabel?.toUpperCase() ?? 'OCR',
            'view': OcrView(groupId: widget.groupId),
          },
          {
            'id': 'gallery',
            'icon': Icons.photo_library_rounded,
            'label': group.galleryLabel ?? 'GALLERY',
            'view': GalleryView(groupId: widget.groupId),
          },
        ];

        // Filter based on group settings
        final activeModules = allModules
            .where((m) => group.enabledModules[m['id']] ?? false)
            .toList();

        if (activeModules.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F6F3),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.go('/home'),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.widgets_outlined,
                      size: 56,
                      color: Color(0xFF5F7465),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'This space has no active modules',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enable at least one module in the space settings.',
                    ),
                    if (group.ownerId ==
                        ref.watch(authRepositoryProvider).currentUser?.uid) ...[
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: () =>
                            context.push('/group/${widget.groupId}/admin'),
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Open settings'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        // Ensure current index is valid
        if (_currentIndex >= activeModules.length) {
          _currentIndex = 0;
        }

        final isDesktop = MediaQuery.sizeOf(context).width >= 900;
        final workspace = LivingBackground(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(group),
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: activeModules
                          .map<Widget>((m) => m['view'] as Widget)
                          .toList(),
                    ),
                  ),
                ],
              ),
              if (!isDesktop)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomNav(group, activeModules),
                ),
              if (activeModules[_currentIndex]['id'] == 'board')
                Positioned(
                  bottom: isDesktop
                      ? 28
                      : 100 + MediaQuery.of(context).padding.bottom,
                  right: isDesktop ? 28 : 16,
                  child: _buildFAB(group),
                ),
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

        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: isDesktop
              ? Row(
                  children: [
                    _buildDesktopSidebar(group, activeModules),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Color(0xFFE2E8E2),
                    ),
                    Expanded(child: workspace),
                  ],
                )
              : workspace,
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildDesktopSidebar(
    dynamic group,
    List<Map<String, dynamic>> activeModules,
  ) {
    return Container(
      width: 246,
      color: const Color(0xFF111813),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Color(int.parse(group.baseColor)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Text(
                    'Hej',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 34),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'SPACE MODULES',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: activeModules.length,
                separatorBuilder: (_, _) => const SizedBox(height: 5),
                itemBuilder: (context, index) {
                  final module = activeModules[index];
                  final selected = index == _currentIndex;
                  return Material(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.11)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => setState(() => _currentIndex = index),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              module['icon'] as IconData,
                              color: selected ? Colors.white : Colors.white54,
                              size: 21,
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Text(
                                (module['label'] as String).toLowerCase(),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white60,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (selected)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD8F3DC),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white12),
            TextButton.icon(
              onPressed: () => context.go('/home'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white60,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.grid_view_rounded, size: 19),
              label: const Text('All spaces'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(group, List<Map<String, dynamic>> activeModules) {
    final activeProposalsCount =
        ref.watch(activeProposalsProvider(widget.groupId)).value?.length ?? 0;

    return SafeArea(
      bottom: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          24,
          0,
          24,
          16,
        ), // Reduced constant margin since SafeArea adds the rest
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.white10),
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
          children: activeModules.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;
            final isCalendar = m['id'] == 'calendar';
            return _buildNavItem(
              idx,
              m['icon'] as IconData,
              m['label'] as String,
              group.fontFamily,
              badgeCount: isCalendar ? activeProposalsCount : 0,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFAB(dynamic group) {
    return FloatingActionButton(
      backgroundColor: Color(int.parse(group.baseColor)),
      child: const Icon(Icons.add, color: Colors.white),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => CreatePostItSheet(
            groupId: widget.groupId,
            baseColor: group.baseColor,
          ),
        );
      },
    );
  }

  Future<void> _extractAI(dynamic group) async {
    final String groupId = group.id;
    // 1. Fetch recent messages
    final messages = await ref.read(chatMessagesProvider(groupId).future);
    if (messages.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough messages to analyze yet!')),
        );
      }
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
      await ref
          .read(geminiControllerProvider.notifier)
          .extractFromChat(groupId, messages);

      if (mounted) Navigator.pop(context); // Pop loading

      // 3. Show suggestions
      if (mounted) {
        final suggestions = ref.read(geminiControllerProvider);
        suggestions.whenData((list) {
          if (!mounted) return;
          if (list.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No new events or takeaways found.'),
              ),
            );
          } else {
            _showSuggestionsDialog(list, group);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI Error: $e')));
      }
    }
  }

  void _showSuggestionsDialog(List<PostIt> suggestions, dynamic group) {
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
                leading: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber,
                ),
                title: Text(s.text),
                subtitle: Text('Color: ${s.textColor}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DISCARD'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              await ref
                  .read(postItControllerProvider.notifier)
                  .saveMultiplePostIts(suggestions);

              if (mounted) {
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Added to Board!')),
                );
                setState(() => _currentIndex = 0); // Switch to board
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(int.parse(group.baseColor)),
              foregroundColor: Colors.white,
            ),
            child: const Text('PIN ALL TO BOARD'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(group) {
    final gradient = AppThemes.getGradient(group.theme);
    final hasBg =
        group.backgroundImage != null && group.backgroundImage!.isNotEmpty;
    final activeProposals =
        ref.watch(activeProposalsProvider(widget.groupId)).value ?? [];
    final hasNew = activeProposals.isNotEmpty;

    return SizedBox(
      height: 80,
      width: double.infinity,
      child: ClipRect(
        child: LivingBackground(
          dark: true,
          child: Container(
            constraints: const BoxConstraints.tightFor(height: 80),
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              gradient: gradient != null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    )
                  : null,
              color: !hasBg && gradient == null ? Colors.transparent : null,
            ),
            child: Stack(
              children: [
                if (hasBg)
                  Positioned.fill(
                    child: Image.network(
                      group.backgroundImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x22000000), Color(0x99000000)],
                      ),
                    ),
                  ),
                ),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.forum_outlined,
                            color: Colors.white70,
                          ),
                          tooltip: 'Private chats',
                          onPressed: () => DirectChatsSheet.show(context),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                          onPressed: () => context.go('/home'),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Badge(
                                isLabelVisible: hasNew,
                                label: Text('${activeProposals.length}'),
                                backgroundColor: Colors.redAccent,
                                child: Hero(
                                  tag: 'group_icon_${group.id}',
                                  child: Text(
                                    group.icon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
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
                                      builder: (context) => MembersListSheet(
                                        groupId: widget.groupId,
                                      ),
                                    );
                                  },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
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
                          icon: const Icon(
                            Icons.person_add_outlined,
                            color: Colors.white70,
                          ),
                          tooltip: 'Invite Members',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Invite to Group'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Share this code with your friends so they can join this group:',
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: SelectableText(
                                              widget.groupId,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.content_copy,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              Clipboard.setData(
                                                ClipboardData(
                                                  text: widget.groupId,
                                                ),
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text('ID copied!'),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('CLOSE'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (group.ownerId ==
                            ref.watch(authRepositoryProvider).currentUser?.uid)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_currentIndex == 1) // Only show on Chat tab
                                IconButton(
                                  icon: const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.amberAccent,
                                  ),
                                  onPressed: () => _extractAI(group),
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.settings_outlined,
                                  color: Colors.white,
                                ),
                                onPressed: () => context.push(
                                  '/group/${widget.groupId}/admin',
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox(
                            width: 48,
                          ), // Spacer to keep title centered
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    String? fontFamily, {
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Badge(
            isLabelVisible: badgeCount > 0,
            label: Text('$badgeCount'),
            backgroundColor: Colors.redAccent,
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white60,
            ),
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
    final hasBg =
        group.backgroundImage != null && group.backgroundImage!.isNotEmpty;
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
                    color: !hasBg && gradient == null
                        ? Color(int.parse(group.baseColor))
                        : null,
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
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
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
