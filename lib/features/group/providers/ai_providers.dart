import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/database_repository.dart';
import '../../../core/services/gemini_repository.dart';
import '../../../core/models/postit.dart';
import '../../../core/models/chat_message.dart';
import '../../auth/data/auth_repository.dart';

part 'ai_providers.g.dart';

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

  Future<String?> generateBackgroundPrompt(String description, {String? style}) async {
    try {
      final gemini = ref.read(geminiRepositoryProvider);
      return await gemini.generateBackgroundPrompt(description, style: style);
    } catch (e) {
      rethrow;
    }
  }
}
