import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/database_repository.dart';
import '../../../core/services/storage_repository.dart';
import '../../../core/models/gallery_item.dart';
import '../../auth/data/auth_repository.dart';

part 'gallery_providers.g.dart';

@riverpod
Stream<List<GalleryItem>> galleryItems(Ref ref, String groupId) {
  return ref.watch(databaseRepositoryProvider).streamGalleryItems(groupId);
}

@riverpod
class GalleryController extends _$GalleryController {
  @override
  FutureOr<void> build() {
    // Idle state
  }

  Future<void> uploadPhoto({
    required String groupId,
    required Uint8List bytes,
    required String fileName,
    required String caption,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      final db = ref.read(databaseRepositoryProvider);
      final storage = ref.read(storageRepositoryProvider);

      // 1. Upload file
      final downloadUrl = await storage.uploadGalleryPhoto(
        groupId: groupId,
        bytes: bytes,
        fileName: fileName,
      );

      // 2. Save metadata
      final id = db.generateGalleryItemId(groupId);
      final galleryItem = GalleryItem(
        id: id,
        groupId: groupId,
        imageUrl: downloadUrl,
        caption: caption,
        uploaderId: user.uid,
        uploaderName: user.displayName ?? 'Member',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await db.saveGalleryItem(galleryItem);
    });
  }

  Future<void> deletePhoto({
    required String groupId,
    required String itemId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseRepositoryProvider);
      await db.deleteGalleryItem(groupId, itemId);
    });
  }
}
