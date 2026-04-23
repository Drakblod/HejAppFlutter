import 'package:firebase_database/firebase_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/meeting_proposal.dart';

part 'meeting_repository.g.dart';

class MeetingRepository {
  final FirebaseDatabase _db;

  MeetingRepository(this._db);

  Stream<List<MeetingProposal>> streamProposals(String groupId) {
    return _db.ref('groupProposals/$groupId').onValue.map((event) {
      final map = event.snapshot.value as Map<dynamic, dynamic>?;
      if (map == null) return [];
      
      final proposals = map.entries.map((e) {
        return MeetingProposal.fromJson(e.key.toString(), e.value as Map<dynamic, dynamic>);
      }).toList();

      // Sort by creation time (desc)
      proposals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return proposals;
    });
  }

  Future<void> createProposal(MeetingProposal proposal) async {
    final ref = _db.ref('groupProposals/${proposal.groupId}').push();
    await ref.set(proposal.toJson());
  }

  Future<void> voteForDate(String groupId, String proposalId, int dateIndex, String userId) async {
    final ref = _db.ref('groupProposals/$groupId/$proposalId/votes/$dateIndex');
    
    // Check if user already voted for this specific date
    final snapshot = await ref.get();
    List<dynamic> currentVotes = (snapshot.value as List<dynamic>?) ?? [];
    
    if (currentVotes.contains(userId)) {
      // Remove vote
      currentVotes.remove(userId);
    } else {
      // Add vote
      currentVotes.add(userId);
    }
    
    await ref.set(currentVotes);
  }

  Future<void> confirmDate(String groupId, String proposalId, DateTime date) async {
    await _db.ref('groupProposals/$groupId/$proposalId').update({
      'finalDate': date.toIso8601String(),
    });
  }

  Future<void> deleteProposal(String groupId, String proposalId) async {
    await _db.ref('groupProposals/$groupId/$proposalId').remove();
  }
}

@riverpod
MeetingRepository meetingRepository(Ref ref) {
  return MeetingRepository(FirebaseDatabase.instance);
}
