import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/group_providers.dart';
import '../widgets/create_group_sheet.dart';
import '../widgets/join_group_sheet.dart';
import '../widgets/group_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(userGroupsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Professional light backdrop
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'HejApp',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Join Group',
            icon: const Icon(Icons.group_add_outlined, color: Color(0xFF1565C0)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const JoinGroupSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Color(0xFF424242)),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_3_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'You haven\'t joined any groups yet.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return GroupCard(
                group: group,
                onTap: () => context.push('/group/${group.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CreateGroupSheet(),
          );
        },
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 6,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('NEW GROUP', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
      ),
    );
  }
}
