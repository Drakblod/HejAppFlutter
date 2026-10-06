import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_repository.g.dart';

class StorageRepository {
  Future<String> _upload(
    String kind,
    Uint8List bytes,
    String fileName, {
    String? groupId,
  }) async {
    if (bytes.length > 6 * 1024 * 1024) {
      throw Exception('Filen får vara högst 6 MB.');
    }
    final result = await FirebaseFunctions.instance
        .httpsCallable(
          'workspaceAccess',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 100)),
        )
        .call({
          'action': 'upload',
          'kind': kind,
          'fileName': fileName,
          'base64': base64Encode(bytes),
          if (groupId != null) 'groupId': groupId,
        });
    return result.data['url'] as String;
  }

  Future<String> uploadChatPhoto({
    required String groupId,
    required Uint8List bytes,
    required String fileName,
  }) => _upload('chat', bytes, fileName, groupId: groupId);
  Future<String> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    required String fileName,
  }) => _upload('profile', bytes, fileName);
  Future<String> uploadGroupBackground({
    required String groupId,
    required Uint8List bytes,
    required String fileName,
  }) => _upload('background', bytes, fileName, groupId: groupId);
  Future<String> uploadSharedFile({
    required String groupId,
    required Uint8List bytes,
    required String fileName,
  }) => _upload('file', bytes, fileName, groupId: groupId);
  Future<String> uploadGalleryPhoto({
    required String groupId,
    required Uint8List bytes,
    required String fileName,
  }) => _upload('gallery', bytes, fileName, groupId: groupId);
}

@riverpod
StorageRepository storageRepository(Ref ref) => StorageRepository();
