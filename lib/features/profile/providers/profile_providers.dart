import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/database_repository.dart';
import '../../../core/services/storage_repository.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../auth/data/auth_repository.dart';

part 'profile_providers.g.dart';

final userProfileProvider = StreamProvider.family<UserProfile?, String>((ref, uid) {
  final db = ref.watch(databaseRepositoryProvider);
  return db.streamProfile(uid);
});

@riverpod
Stream<UserProfile?> currentUserProfile(Ref ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(null);
  
  final db = ref.watch(databaseRepositoryProvider);
  
  // Return a stream that monitors the standardized /profiles/ node
  return db.streamProfile(user.uid).asyncMap((profile) async {
    if (profile == null) {
      // MIGRATION LOGIC: Check if profile exists in the old /users/ node
      final snapshot = await FirebaseDatabase.instance.ref('users/${user.uid}').get();
      if (snapshot.exists) {
        final legacyMap = snapshot.value as Map<dynamic, dynamic>;
        final legacyProfile = UserProfile.fromJson(user.uid, legacyMap);
        // Automatically migrate to the new location
        await db.createUserProfile(legacyProfile);
        return legacyProfile;
      }
    }
    return profile;
  });
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
    Uint8List? photoBytes,
    String? photoFileName,
  }) async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      final dbRepo = ref.read(databaseRepositoryProvider);
      final user = authRepo.currentUser;
      
      if (user == null) throw Exception('Not signed in');

      final currentProfile = await dbRepo.getProfile(user.uid);
      final oldUsername = currentProfile?.username;

      String? photoUrl = currentProfile?.photoUrl;
      if (photoBytes != null && photoFileName != null) {
        photoUrl = await ref.read(storageRepositoryProvider).uploadProfilePhoto(
          uid: user.uid,
          bytes: photoBytes,
          fileName: photoFileName,
        );
      }

      // 1. Check Username Availability if changed
      if (username != oldUsername) {
        final available = await dbRepo.isUsernameAvailable(username);
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

      // Update Database
      await dbRepo.updateProfile(profile, oldUsername: oldUsername);
      
      // Sync to Firebase Auth displayName
      await user.updateDisplayName(fullName);
    });
  }
}
