import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/database_repository.dart';
import '../../../core/models/suggestion.dart';
import '../../auth/data/auth_repository.dart';

part 'suggestions_providers.g.dart';

@riverpod
Stream<List<Suggestion>> suggestions(Ref ref) {
  return ref.watch(databaseRepositoryProvider).streamSuggestions();
}

@riverpod
class SuggestionsController extends _$SuggestionsController {
  @override
  FutureOr<void> build() {
    // Idle state
  }

  Future<void> addSuggestion({
    required String title,
    required String description,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      final db = ref.read(databaseRepositoryProvider);
      final id = db.generateSuggestionId();
      
      final suggestion = Suggestion(
        id: id,
        groupId: '',
        title: title,
        description: description,
        authorId: user.uid,
        authorName: user.displayName ?? 'Member',
        status: 'new',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await db.saveSuggestion(suggestion);
    });
  }

  Future<void> updateStatus({
    required String suggestionId,
    required String newStatus,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseRepositoryProvider);
      await db.updateSuggestionStatus(suggestionId, newStatus);
    });
  }

  Future<void> deleteSuggestion({
    required String suggestionId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseRepositoryProvider);
      await db.deleteSuggestion(suggestionId);
    });
  }
}
