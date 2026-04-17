import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/database_repository.dart';
import '../../../core/services/storage_repository.dart';
import '../../auth/data/auth_repository.dart';

part 'profile_providers.g.dart';

@riverpod
Stream<UserProfile?> currentUserProfile(Ref ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(null);
  
  // Actually we might want to watch the real-time node
  // But for now, let's use a simple fetch or a stream if available
  // The databaseRepository doesn't have a streamProfile yet, let's add one or use a future.
  // Actually, keeping it as a Stream is better for real-time UI updates.
  return Stream.fromFuture(ref.watch(databaseRepositoryProvider).getProfile(user.uid));
}

@riverpod
class ProfileController extends _$ProfileController {
  @override
  FutureOr<void> build() {
    // Idle state
  }

  Future<void> updateProfile({
    required String username,
    required String fullName,
    String? bio,
    File? photoFile,
  }) async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('Not signed in');

      final currentProfile = await ref.read(databaseRepositoryProvider).getProfile(user.uid);
      final oldUsername = currentProfile?.username;

      String? photoUrl = currentProfile?.photoUrl;
      if (photoFile != null) {
        photoUrl = await ref.read(storageRepositoryProvider).uploadProfilePhoto(
          uid: user.uid,
          file: photoFile,
        );
      }

      // 1. Check Username Availability if changed
      if (username != oldUsername) {
        final available = await ref.read(databaseRepositoryProvider).isUsernameAvailable(username);
        if (!available) throw Exception('Username is already taken');
      }

      final profile = UserProfile(
        uid: user.uid,
        username: username,
        fullName: fullName,
        bio: bio,
        photoUrl: photoUrl,
        email: user.email,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await ref.read(databaseRepositoryProvider).updateProfile(profile, oldUsername: oldUsername);
    });
  }
}
