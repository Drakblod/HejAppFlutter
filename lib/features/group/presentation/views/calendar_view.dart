import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/meeting_providers.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../core/services/meeting_repository.dart';
import '../../providers/board_providers.dart';
import '../widgets/create_proposal_dialog.dart';

class CalendarView extends ConsumerWidget {
  final String groupId;

  const CalendarView({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeProposalsProvider(groupId));
    final confirmedAsync = ref.watch(confirmedMeetingsProvider(groupId));
    final groupAsync = ref.watch(groupMetaProvider(groupId));
    final currentUser = ref.watch(authRepositoryProvider).currentUser;

    return Container(
      color: const Color(0xFFF5F5F5),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(groupProposalsProvider(groupId));
          ref.invalidate(groupMetaProvider(groupId));
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            // Header for Confirmed
            _SectionHeader(
              title: 'CONFIRMED GATHERINGS',
              icon: Icons.check_circle_outline,
              onAdd: () {
                final isOwner = groupAsync.value?.ownerId == currentUser?.uid;
                if (isOwner) {
                  showDialog(
                    context: context,
                    builder: (context) => CreateProposalDialog(groupId: groupId),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Only group admins can propose meetings')),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            confirmedAsync.when(
              data: (meetings) => meetings.isEmpty
                  ? const _EmptyState(text: 'No confirmed gatherings yet')
                  : Column(
                      children: meetings.map((m) => _ConfirmedMeetingCard(meeting: m)).toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
  
            const SizedBox(height: 32),
  
            // Header for Proposals
            const _SectionHeader(
              title: 'ACTIVE PROPOSALS',
              icon: Icons.lightbulb_outline,
            ),
            const SizedBox(height: 12),
            activeAsync.when(
              data: (proposals) => proposals.isEmpty
                  ? const _EmptyState(text: 'No active proposals. Start one!')
                  : Column(
                      children: proposals.map((p) => _ProposalCard(
                        proposal: p,
                        isOwner: groupAsync.value?.ownerId == currentUser?.uid,
                        currentUserId: currentUser?.uid ?? '',
                      )).toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onAdd;

  const _SectionHeader({required this.title, required this.icon, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        if (onAdd != null)
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF2F7D32)),
            onPressed: onAdd,
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.black38, fontSize: 14)),
      ),
    );
  }
}

class _ConfirmedMeetingCard extends StatelessWidget {
  final dynamic meeting;
  const _ConfirmedMeetingCard({required this.meeting});

  @override
  Widget build(BuildContext context) {
    final date = meeting.finalDate!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F7D32).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('MMM').format(date).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('dd').format(date),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meeting.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  DateFormat('EEEE, HH:mm').format(date),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposalCard extends ConsumerWidget {
  final dynamic proposal;
  final bool isOwner;
  final String currentUserId;

  const _ProposalCard({
    required this.proposal,
    required this.isOwner,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proposal.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    if (proposal.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          proposal.description,
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => ref.read(meetingRepositoryProvider).deleteProposal(proposal.groupId, proposal.id),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Pick your availability:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black38)),
          const SizedBox(height: 8),
          ...List.generate(proposal.proposedDates.length, (index) {
            final date = proposal.proposedDates[index];
            final votes = proposal.votes[index] ?? [];
            final hasVoted = votes.contains(currentUserId);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () => ref.read(meetingRepositoryProvider).voteForDate(
                  proposal.groupId,
                  proposal.id,
                  index,
                  currentUserId,
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: hasVoted ? const Color(0xFFE8F5E9) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasVoted ? const Color(0xFF2F7D32).withValues(alpha: 0.3) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasVoted ? Icons.check_circle : Icons.circle_outlined,
                        color: hasVoted ? const Color(0xFF2F7D32) : Colors.black12,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat('EEE, MMM d • HH:mm').format(date),
                          style: TextStyle(
                            color: hasVoted ? const Color(0xFF1B5E20) : Colors.black87,
                            fontWeight: hasVoted ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${votes.length} votes',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isOwner)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: InkWell(
                            onTap: () => _confirmMeeting(context, ref, proposal, date),
                            child: const Icon(Icons.stars, color: Colors.amber, size: 24),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _confirmMeeting(BuildContext context, WidgetRef ref, dynamic proposal, DateTime date) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Date?'),
        content: Text('Do you want to set ${DateFormat('MMM d, HH:mm').format(date)} as the final date for "${proposal.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F7D32), foregroundColor: Colors.white),
            child: const Text('CONFIRM DATE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(meetingRepositoryProvider).confirmDate(proposal.groupId, proposal.id, date);
    }
  }
}
