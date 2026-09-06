import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/group_providers.dart';
import '../widgets/create_group_sheet.dart';
import '../widgets/join_group_sheet.dart';
import '../widgets/group_card.dart';
import '../../../../core/widgets/living_background.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showCreateGroup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateGroupSheet(),
    );
  }

  void _showJoinGroup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const JoinGroupSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(userGroupsProvider);

    return LivingBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 76,
          titleSpacing: 24,
          title: const _Brand(),
          actions: [
            TextButton.icon(
              onPressed: () => _showJoinGroup(context),
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('Join a space'),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Your profile',
              icon: const Icon(Icons.person_outline_rounded),
              onPressed: () => context.push('/profile'),
            ),
            const SizedBox(width: 24),
          ],
        ),
        body: groupsAsync.when(
          data: (groups) => LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 32 : 20,
                      20,
                      isWide ? 32 : 20,
                      24,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1180),
                          child: _WelcomePanel(
                            groupCount: groups.length,
                            onCreate: () => _showCreateGroup(context),
                            onJoin: () => _showJoinGroup(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (groups.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        onCreate: () => _showCreateGroup(context),
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isWide ? 32 : 20,
                        4,
                        isWide ? 32 : 20,
                        14,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1180),
                            child: Row(
                              children: [
                                Text(
                                  'Your spaces',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                                const Spacer(),
                                Text(
                                  '${groups.length} ${groups.length == 1 ? 'space' : 'spaces'}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isWide ? 32 : 20,
                        0,
                        isWide ? 32 : 20,
                        110,
                      ),
                      sliver: SliverLayoutBuilder(
                        builder: (context, gridConstraints) {
                          final width = gridConstraints.crossAxisExtent
                              .clamp(0, 1180)
                              .toDouble();
                          final columns = width >= 1050
                              ? 3
                              : width >= 680
                              ? 2
                              : 1;
                          return SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisExtent: 154,
                                  crossAxisSpacing: 18,
                                  mainAxisSpacing: 18,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final group = groups[index];
                              return GroupCard(
                                group: group,
                                onTap: () => context.push('/group/${group.id}'),
                              );
                            }, childCount: groups.length),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => _ErrorState(message: err.toString()),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateGroup(context),
          backgroundColor: const Color(0xFF225C32),
          foregroundColor: Colors.white,
          elevation: 2,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create space'),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF225C32),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.chat_bubble_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        const Text(
          'Hej',
          style: TextStyle(
            color: Color(0xFF17231A),
            fontWeight: FontWeight.w900,
            fontSize: 25,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  final int groupCount;
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _WelcomePanel({
    required this.groupCount,
    required this.onCreate,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF173F28),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A173F28),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 610),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupCount == 0
                      ? 'Build your first space'
                      : 'Everything your group needs',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Bring conversations, plans, files and shared memories together — in a space that feels like yours.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.76),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onJoin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 17,
                  ),
                ),
                icon: const Icon(Icons.add_link_rounded),
                label: const Text('Join'),
              ),
              FilledButton.icon(
                onPressed: onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD8F3DC),
                  foregroundColor: const Color(0xFF173F28),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 17,
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create a space'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.dashboard_customize_outlined,
              size: 58,
              color: Colors.green[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No spaces yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            const Text(
              'Create a space and choose the modules your group needs.',
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onCreate,
              child: const Text('Create your first space'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 14),
            Text(
              'We could not load your spaces',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
