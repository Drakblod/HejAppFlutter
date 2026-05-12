import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import '../../../core/services/database_repository.dart';
import '../../../core/models/group.dart';
import '../../../core/models/group_member.dart';
import '../../../core/models/user_profile.dart';
import '../models/board_item.dart';
import '../../../features/auth/data/auth_repository.dart';

part 'board_providers.g.dart';

@riverpod
Stream<Group?> groupMeta(Ref ref, String groupId) {
  return ref.watch(databaseRepositoryProvider).streamGroupMeta(groupId);
}

@riverpod
Stream<List<BoardItem>> boardItems(Ref ref, String groupId) {
  final db = ref.watch(databaseRepositoryProvider);
  final auth = ref.watch(authRepositoryProvider);
  final userId = auth.currentUser?.uid;

  final messagesStream = db.streamMessages(groupId, limit: 30).startWith([]);
  final postItsStream = db.streamPostIts(groupId).startWith([]);
  
  // Watch current user's membership for lastReadTs
  final memberStream = userId != null 
      ? db.streamMember(groupId, userId).startWith(null)
      : Stream<GroupMember?>.value(null);

  return CombineLatestStream.combine3(
    messagesStream,
    postItsStream,
    memberStream,
    (messages, postIts, member) {
      final items = <BoardItem>[];
      final lastRead = member?.lastReadTs ?? 0;
      
      // Filter chat messages: Only show those newer than lastReadTs
      final unreadMessages = messages.where((m) => m.ts > lastRead);
      
      items.addAll(unreadMessages.map((m) => BoardItem.fromMessage(m)));
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
