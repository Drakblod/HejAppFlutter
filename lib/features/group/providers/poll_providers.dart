import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/group_poll.dart';
import '../../../core/services/database_repository.dart';

final groupPollsProvider = StreamProvider.autoDispose
    .family<List<GroupPoll>, String>((ref, groupId) {
      return ref.watch(databaseRepositoryProvider).streamPolls(groupId);
    });
