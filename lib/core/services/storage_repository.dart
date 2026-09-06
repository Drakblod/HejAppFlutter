import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_repository.g.dart';

class StorageRepository {
  final FirebaseStorage _storage;

  StorageRepository(this._storage);

  String _guessContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  Future<String> uploadChatPhoto({
    required String groupId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref().child('chat_photos').child(groupId).child(name);
    
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: _guessContentType(fileName)),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref().child('profile_photos').child(uid).child(name);
    
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: _guessContentType(fileName)),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadGroupBackground({
    required String groupId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final name = 'bg_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref().child('group_backgrounds').child(groupId).child(name);
    
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: _guessContentType(fileName)),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadSharedFile({
    required String groupId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref().child('shared_files').child(groupId).child(name);
    
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(
        contentDisposition: 'attachment; filename="$fileName"',
      ),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadGalleryPhoto({
    required String groupId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref().child('gallery_photos').child(groupId).child(name);
    
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: _guessContentType(fileName)),
    );
    return await uploadTask.ref.getDownloadURL();
  }
}

@riverpod
StorageRepository storageRepository(Ref ref) {
  return StorageRepository(FirebaseStorage.instance);
}
