import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/board_providers.dart';

class MembersListSheet extends ConsumerWidget {
  final String groupId;

  const MembersListSheet({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final groupAsync = ref.watch(groupMetaProvider(groupId));

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Group Members',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          groupAsync.when(
            data: (group) {
              if (group?.description != null && group!.description!.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ABOUT THIS GROUP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black38,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            group.description!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          membersAsync.when(
            data: (members) => ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final m = members[index];
                final isOwner = m.member.role == 'owner';
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: m.profile?.photoUrl != null ? NetworkImage(m.profile!.photoUrl!) : null,
                        child: m.profile?.photoUrl == null ? const Icon(Icons.person, size: 20) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.profile?.username ?? 'User',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              isOwner ? 'Group Owner' : 'Member',
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (isOwner)
                        const Icon(Icons.verified_user, color: Colors.blue, size: 18),
                    ],
                  ),
                );
              },
            ),
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }
}
