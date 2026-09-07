import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/group_task.dart';
import '../../../core/services/database_repository.dart';

final groupTasksProvider = StreamProvider.autoDispose
    .family<List<GroupTask>, String>(
      (ref, groupId) =>
          ref.watch(databaseRepositoryProvider).streamTasks(groupId),
    );
