import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/group_task.dart';
import '../../../../core/services/database_repository.dart';
import '../../../auth/data/auth_repository.dart';
import '../../providers/board_providers.dart';
import '../../providers/task_providers.dart';

class TasksView extends ConsumerWidget {
  final String groupId;
  const TasksView({super.key, required this.groupId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupMetaProvider(groupId)).value;
    final color = Color(int.parse(group?.baseColor ?? '0xFF2F7D32'));
    final tasks = ref.watch(groupTasksProvider(groupId));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TASKS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Turn decisions into action',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _CreateTaskSheet.show(context, groupId),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New task'),
              style: FilledButton.styleFrom(backgroundColor: color),
            ),
          ],
        ),
        const SizedBox(height: 22),
        tasks.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Text('Could not load tasks: $error'),
          data: (items) => items.isEmpty
              ? const _EmptyTasks()
              : Column(
                  children: items
                      .map(
                        (task) => _TaskCard(
                          task: task,
                          groupId: groupId,
                          color: color,
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final GroupTask task;
  final String groupId;
  final Color color;
  const _TaskCard({
    required this.task,
    required this.groupId,
    required this.color,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(groupMembersProvider(groupId)).value ?? [];
    final person = task.assigneeId == null
        ? null
        : members
              .where((member) => member.member.uid == task.assigneeId)
              .firstOrNull
              ?.profile;
    final name = person?.fullName.isNotEmpty == true
        ? person!.fullName
        : person?.username;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(18),
      ),
      child: CheckboxListTile(
        value: task.isDone,
        activeColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onChanged: (value) => ref
            .read(databaseRepositoryProvider)
            .setTaskDone(groupId, task.id, value ?? false),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            color: task.isDone ? Colors.black45 : null,
          ),
        ),
        subtitle: Text(
          [
            if (name != null) name,
            if (task.dueAt != null)
              'Due ${DateFormat('d MMM').format(DateTime.fromMillisecondsSinceEpoch(task.dueAt!))}',
          ].join(' · '),
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(36),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Column(
      children: [
        Icon(Icons.task_alt_rounded, size: 42, color: Color(0xFF52735A)),
        SizedBox(height: 14),
        Text(
          'Nothing to do yet',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        SizedBox(height: 6),
        Text(
          'Create a task and give the group a clear next step.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ],
    ),
  );
}

class _CreateTaskSheet extends ConsumerStatefulWidget {
  final String groupId;
  const _CreateTaskSheet({required this.groupId});
  static Future<void> show(BuildContext context, String groupId) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _CreateTaskSheet(groupId: groupId),
      );
  @override
  ConsumerState<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<_CreateTaskSheet> {
  final title = TextEditingController();
  String? assignee;
  DateTime? dueAt;
  bool saving = false;
  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(groupMembersProvider(widget.groupId)).value ?? [];
    return Padding(
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
                  'New task',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: title,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'What needs to happen?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: assignee,
                  decoration: const InputDecoration(
                    labelText: 'Assign to',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Unassigned'),
                    ),
                    ...members.map(
                      (member) => DropdownMenuItem(
                        value: member.member.uid,
                        child: Text(
                          member.profile?.fullName.isNotEmpty == true
                              ? member.profile!.fullName
                              : member.profile?.username ?? 'Member',
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => assignee = value),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Deadline'),
                  subtitle: Text(
                    dueAt == null
                        ? 'No deadline'
                        : DateFormat('d MMMM').format(dueAt!),
                  ),
                  onTap: _pickDate,
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving ? null : _save,
                    child: saving
                        ? const CircularProgressIndicator()
                        : const Text('CREATE TASK'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: dueAt ?? DateTime.now(),
    );
    if (value != null) setState(() => dueAt = value);
  }

  Future<void> _save() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null || title.text.trim().isEmpty) return;
    setState(() => saving = true);
    await ref
        .read(databaseRepositoryProvider)
        .createTask(
          groupId: widget.groupId,
          title: title.text.trim(),
          creatorId: user.uid,
          assigneeId: assignee,
          dueAt: dueAt?.millisecondsSinceEpoch,
        );
    if (mounted) Navigator.pop(context);
  }
}
