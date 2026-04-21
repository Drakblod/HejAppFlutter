import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import '../../../core/services/database_repository.dart';
import '../../../core/models/group.dart';
import '../../../core/models/group_member.dart';
import '../../../core/models/user_profile.dart';
import '../models/board_item.dart';

part 'board_providers.g.dart';

@riverpod
Future<Group?> groupMeta(Ref ref, String groupId) {
  return ref.watch(databaseRepositoryProvider).getGroupMeta(groupId);
}

@riverpod
Stream<List<BoardItem>> boardItems(Ref ref, String groupId) {
  final db = ref.watch(databaseRepositoryProvider);

  final messagesStream = db.streamMessages(groupId, limit: 30).startWith([]);
  final postItsStream = db.streamPostIts(groupId).startWith([]);

  return CombineLatestStream.combine2(
    messagesStream,
    postItsStream,
    (messages, postIts) {
      final items = <BoardItem>[];
      
      items.addAll(messages.map((m) => BoardItem.fromMessage(m)));
      items.addAll(postIts.map((p) => BoardItem.fromPostIt(p)));

      // Sort by timestamp descending (newest first)
      items.sort((a, b) => b.ts.compareTo(a.ts));
      
      return items;
    },
  );
}

@riverpod
Stream<List<({GroupMember member, UserProfile? profile})>> groupMembers(Ref ref, String groupId) {
  final db = ref.watch(databaseRepositoryProvider);
  
  return db.streamMembers(groupId).switchMap((members) {
    if (members.isEmpty) return Stream.value([]);
    
    // For each member, we need to fetch their profile.
    // To keep it reactive, we could stream each profile, but that's expensive.
    // For a settings page, a simple Future.wait is often enough if we re-trigger on member list changes.
    // However, let's try a reactive approach using CombineLatest.
    
    final profileStreams = members.map((m) {
      return db.streamProfile(m.uid).map((p) => (member: m, profile: p));
    });
    
    return CombineLatestStream.list(profileStreams);
  });
}
