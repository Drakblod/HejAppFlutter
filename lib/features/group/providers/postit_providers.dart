import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/models/postit.dart';
import '../../../core/services/database_repository.dart';
import '../../../core/services/gemini_repository.dart';
import '../../../core/models/chat_message.dart';
import '../../../features/auth/data/auth_repository.dart';

part 'postit_providers.g.dart';

@riverpod
class PostItController extends _$PostItController {
  @override
  FutureOr<void> build() {}

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
}

@riverpod
class GeminiController extends _$GeminiController {
  @override
  FutureOr<List<PostIt>> build() => [];

  Future<void> extractFromChat(String groupId, List<ChatMessage> messages) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final gemini = ref.read(geminiRepositoryProvider);
      final auth = ref.read(authRepositoryProvider);
      final db = ref.read(databaseRepositoryProvider);
      
      final suggestions = await gemini.extractPostIts(messages);
      
      return suggestions.map((s) {
        return PostIt(
          id: db.generatePostItId(groupId),
          groupId: groupId,
          senderId: auth.currentUser?.uid ?? 'ai',
          text: s['text'] ?? 'New Idea',
          textColor: s['color'] ?? 'yellow',
          ts: DateTime.now().millisecondsSinceEpoch,
        );
      }).toList();
    });
  }

  Future<String?> generateBackgroundPrompt(String description) async {
    try {
      final gemini = ref.read(geminiRepositoryProvider);
      return await gemini.generateBackgroundPrompt(description);
    } catch (e) {
      return null;
    }
  }
}
