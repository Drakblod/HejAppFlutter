import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/auth_repository.dart';
import '../../../core/services/database_repository.dart';
import '../../../core/models/user_profile.dart';

part 'auth_providers.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {
    // Initial state is idle
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signIn(email, password);
    });
  }

  Future<void> register({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final credential = await ref.read(authRepositoryProvider).signUp(email, password);
      final uid = credential.user!.uid;

      // Also set displayName on Firebase user for fallback
      await credential.user!.updateDisplayName(username);

      // Create profile in database (now standardized to /profiles/ in repository)
      final profile = UserProfile(
        uid: uid,
        username: username,
        fullName: username,
        email: email,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await ref.read(databaseRepositoryProvider).createUserProfile(profile);
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
    });
  }
}
