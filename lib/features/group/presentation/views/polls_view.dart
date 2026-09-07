import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/group_poll.dart';
import '../../../../core/services/database_repository.dart';
import '../../../auth/data/auth_repository.dart';
import '../../providers/board_providers.dart';
import '../../providers/poll_providers.dart';

class PollsView extends ConsumerWidget {
  final String groupId;
  const PollsView({super.key, required this.groupId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupMetaProvider(groupId)).value;
    final user = ref.watch(authRepositoryProvider).currentUser;
    final owner = group?.ownerId == user?.uid;
    final color = Color(int.parse(group?.baseColor ?? '0xFF2F7D32'));
    final polls = ref.watch(groupPollsProvider(groupId));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(groupPollsProvider(groupId)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DECISIONS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Make a choice together',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (owner)
                FilledButton.icon(
                  onPressed: () => _CreatePollSheet.show(context, groupId),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New poll'),
                  style: FilledButton.styleFrom(backgroundColor: color),
                ),
            ],
          ),
          const SizedBox(height: 22),
          polls.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text('Could not load polls: $error'),
            data: (items) => items.isEmpty
                ? const _EmptyPolls()
                : Column(
                    children: items
                        .map(
                          (poll) => _PollCard(
                            poll: poll,
                            groupId: groupId,
                            userId: user?.uid,
                            owner: owner,
                            color: color,
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PollCard extends ConsumerWidget {
  final GroupPoll poll;
  final String groupId;
  final String? userId;
  final bool owner;
  final Color color;
  const _PollCard({
    required this.poll,
    required this.groupId,
    required this.userId,
    required this.owner,
    required this.color,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = poll.votes.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  poll.question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _Status(open: poll.isOpen, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            poll.isOpen
                ? 'Closes ${DateFormat('d MMM, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(poll.closesAt))}'
                : '$total votes cast',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            poll.options.length,
            (index) => _PollOption(
              poll: poll,
              index: index,
              total: total,
              userId: userId,
              groupId: groupId,
              color: color,
            ),
          ),
          if (owner && poll.isOpen)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => ref
                    .read(databaseRepositoryProvider)
                    .closePoll(groupId, poll.id),
                icon: const Icon(Icons.lock_outline_rounded, size: 17),
                label: const Text('Close poll'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  final bool open;
  final Color color;
  const _Status({required this.open, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: (open ? color : Colors.black54).withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      open ? 'OPEN' : 'CLOSED',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: open ? color : Colors.black54,
      ),
    ),
  );
}

class _PollOption extends ConsumerWidget {
  final GroupPoll poll;
  final int index;
  final int total;
  final String? userId;
  final String groupId;
  final Color color;
  const _PollOption({
    required this.poll,
    required this.index,
    required this.total,
    required this.userId,
    required this.groupId,
    required this.color,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = poll.votesFor(index);
    final selected = poll.votes[userId] == '$index';
    final ratio = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: poll.isOpen && userId != null
            ? () => ref
                  .read(databaseRepositoryProvider)
                  .voteInPoll(
                    groupId: groupId,
                    pollId: poll.id,
                    userId: userId!,
                    optionIndex: index,
                  )
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: .11)
                : const Color(0xFFF3F6F3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? color : Colors.transparent),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      poll.options[index],
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                borderRadius: BorderRadius.circular(9),
                color: color,
                backgroundColor: color.withValues(alpha: .12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPolls extends StatelessWidget {
  const _EmptyPolls();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(36),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Column(
      children: [
        Icon(Icons.how_to_vote_outlined, size: 42, color: Color(0xFF52735A)),
        SizedBox(height: 14),
        Text(
          'No decisions waiting',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        SizedBox(height: 6),
        Text(
          'Create a poll to let the group decide together.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ],
    ),
  );
}

class _CreatePollSheet extends ConsumerStatefulWidget {
  final String groupId;
  const _CreatePollSheet({required this.groupId});
  static Future<void> show(BuildContext context, String groupId) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _CreatePollSheet(groupId: groupId),
      );
  @override
  ConsumerState<_CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends ConsumerState<_CreatePollSheet> {
  final question = TextEditingController();
  final options = [TextEditingController(), TextEditingController()];
  DateTime closesAt = DateTime.now().add(const Duration(days: 3));
  bool saving = false;
  @override
  void dispose() {
    question.dispose();
    for (final option in options) {
      option.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New poll',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: question,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'What should the group decide?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              ...options.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: 'Option ${entry.key + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              if (options.length < 4)
                TextButton.icon(
                  onPressed: () =>
                      setState(() => options.add(TextEditingController())),
                  icon: const Icon(Icons.add),
                  label: const Text('Add option'),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Voting closes'),
                subtitle: Text(
                  DateFormat('EEEE d MMM, HH:mm').format(closesAt),
                ),
                onTap: _pickDate,
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving ? null : _save,
                  child: saving
                      ? const CircularProgressIndicator()
                      : const Text('CREATE POLL'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: closesAt,
    );
    if (date != null)
      setState(() => closesAt = DateTime(date.year, date.month, date.day, 18));
  }

  Future<void> _save() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    final choices = options
        .map((option) => option.text.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (user == null || question.text.trim().isEmpty || choices.length < 2)
      return;
    setState(() => saving = true);
    await ref
        .read(databaseRepositoryProvider)
        .createPoll(
          groupId: widget.groupId,
          question: question.text.trim(),
          options: choices,
          creatorId: user.uid,
          closesAt: closesAt.millisecondsSinceEpoch,
        );
    if (mounted) Navigator.pop(context);
  }
}
