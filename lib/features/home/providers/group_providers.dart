import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/models/group.dart';
import '../../../core/services/database_repository.dart';
import '../../auth/data/auth_repository.dart';

part 'group_providers.g.dart';

@riverpod
Stream<List<Group>> userGroups(Ref ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);

  final db = ref.watch(databaseRepositoryProvider);
  
  // 1. Get the stream of group IDs for this user
  // 2. Map those IDs to actual Group metadata
  return db.streamUserGroupIds(user.uid).asyncMap((groupIds) async {
    final groups = <Group>[];
    for (final id in groupIds) {
      final meta = await db.getGroupMeta(id);
      if (meta != null) groups.add(meta);
    }
    return groups;
  });
}
