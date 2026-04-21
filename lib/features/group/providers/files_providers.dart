import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/database_repository.dart';
import '../../../core/services/storage_repository.dart';
import '../../../core/models/shared_file.dart';
import '../../auth/data/auth_repository.dart';

part 'files_providers.g.dart';

@riverpod
Stream<List<SharedFile>> sharedFiles(Ref ref, String groupId) {
  return ref.watch(databaseRepositoryProvider).streamSharedFiles(groupId);
}

@riverpod
class FilesController extends _$FilesController {
  @override
  FutureOr<void> build() {
    ref.keepAlive();
  }

  Future<void> pickAndUploadFile(String groupId) async {
    state = const AsyncValue.loading();
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (!ref.mounted) return;

    state = await AsyncValue.guard(() async {

      if (result == null || result.files.isEmpty) return;

      final platformFile = result.files.first;
      if (platformFile.path == null) return;

      final file = File(platformFile.path!);
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;

      final db = ref.read(databaseRepositoryProvider);
      final storage = ref.read(storageRepositoryProvider);

      // 1. Upload to storage
      final downloadUrl = await storage.uploadSharedFile(
        groupId: groupId,
        file: file,
      );

      // 2. Save metadata
      final fileId = db.generateFileId(groupId);
      final sharedFile = SharedFile(
        id: fileId,
        groupId: groupId,
        name: platformFile.name,
        url: downloadUrl,
        type: platformFile.extension ?? 'unknown',
        size: platformFile.size,
        senderId: user.uid,
        senderName: user.displayName ?? 'Member',
        ts: DateTime.now().millisecondsSinceEpoch,
      );

      await db.saveSharedFileMetadata(sharedFile);
    });
  }
}
