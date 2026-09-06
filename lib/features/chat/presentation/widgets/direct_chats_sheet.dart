import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../features/profile/providers/profile_providers.dart';
import '../../providers/chat_providers.dart';

class DirectChatsSheet extends ConsumerWidget {
  const DirectChatsSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const DirectChatsSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    final chatsAsync = ref.watch(directConversationsProvider(uid));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .72,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: Color(0xFF225C32)),
                SizedBox(width: 10),
                Text(
                  'Private chats',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: chatsAsync.when(
                data: (chats) {
                  if (chats.isEmpty) return const _EmptyDirectChats();
                  return ListView.separated(
                    itemCount: chats.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final otherUid = chats[index].otherParticipant(uid);
                      if (otherUid == null) return const SizedBox.shrink();
                      return _DirectChatRow(
                        otherUid: otherUid,
                        preview: chats[index].lastMessage,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Could not load private chats: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectChatRow extends ConsumerWidget {
  final String otherUid;
  final String? preview;
  const _DirectChatRow({required this.otherUid, this.preview});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider(otherUid)).value;
    final name = profile?.fullName.trim().isNotEmpty == true
        ? profile!.fullName
        : profile?.username.trim().isNotEmpty == true
        ? profile!.username
        : 'Member';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      onTap: () {
        Navigator.pop(context);
        context.push('/direct/$otherUid');
      },
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE4EEE5),
        backgroundImage: profile?.photoUrl != null
            ? NetworkImage(profile!.photoUrl!)
            : null,
        child: profile?.photoUrl == null
            ? Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF225C32),
                  fontWeight: FontWeight.w800,
                ),
              )
            : null,
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        preview?.trim().isNotEmpty == true
            ? preview!
            : 'Start your private conversation',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black38),
    );
  }
}

class _EmptyDirectChats extends StatelessWidget {
  const _EmptyDirectChats();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 42, color: Color(0xFF77917D)),
          SizedBox(height: 14),
          Text(
            'No private chats yet',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          SizedBox(height: 7),
          Text(
            'Tap a member in the group chat to start one.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}
