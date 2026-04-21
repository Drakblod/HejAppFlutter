import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/models/postit.dart';
import '../../../core/services/database_repository.dart';
import '../../../features/auth/data/auth_repository.dart';

part 'postit_providers.g.dart';

@riverpod
class PostItController extends _$PostItController {
  @override
  FutureOr<void> build() {
    ref.keepAlive();
  }

  Future<void> savePostIt({
    required String groupId,
    required String text,
    required String textColor,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseRepositoryProvider);
      final auth = ref.read(authRepositoryProvider);
      final id = db.generatePostItId(groupId);
      
      final postIt = PostIt(
        id: id,
        groupId: groupId,
        senderId: auth.currentUser?.uid ?? 'anonymous',
        text: text,
        textColor: textColor,
        ts: DateTime.now().millisecondsSinceEpoch,
      );
      
      await db.savePostIt(postIt);
    });
  }

  Future<void> saveMultiplePostIts(List<PostIt> postIts) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseRepositoryProvider);
      for (final p in postIts) {
        await db.savePostIt(p);
      }
    });
  }

  Future<void> deletePostIt(String groupId, String postItId) async {
    print('[DELETE_DEBUG] Controller: deletePostIt(groupId: $groupId, id: $postItId)');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(databaseRepositoryProvider).deletePostIt(groupId, postItId);
    });
  }
}

