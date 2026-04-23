import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/meeting_repository.dart';
import '../../../core/models/meeting_proposal.dart';

part 'meeting_providers.g.dart';

@riverpod
Stream<List<MeetingProposal>> groupProposals(Ref ref, String groupId) {
  return ref.watch(meetingRepositoryProvider).streamProposals(groupId);
}

@riverpod
Stream<List<MeetingProposal>> activeProposals(Ref ref, String groupId) {
  return ref.watch(meetingRepositoryProvider).streamProposals(groupId).map((list) {
    return list.where((p) => !p.isConfirmed).toList();
  });
}

@riverpod
Stream<List<MeetingProposal>> confirmedMeetings(Ref ref, String groupId) {
  return ref.watch(meetingRepositoryProvider).streamProposals(groupId).map((list) {
    return list.where((p) => p.isConfirmed).toList();
  });
}
