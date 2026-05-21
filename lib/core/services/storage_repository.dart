import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_repository.g.dart';

class StorageRepository {
  final FirebaseStorage _storage;

  StorageRepository(this._storage);

  Future<String> uploadChatPhoto({
    required String groupId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref().child('chat_photos').child(groupId).child(name);
    
    final uploadTask = await ref.putData(bytes);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref().child('profile_photos').child(uid).child(name);
    
    final uploadTask = await ref.putData(bytes);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadGroupBackground({
    required String groupId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final name = 'bg_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref().child('group_backgrounds').child(groupId).child(name);
    
    final uploadTask = await ref.putData(bytes);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadSharedFile({
    required String groupId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref().child('shared_files').child(groupId).child(name);
    
    final uploadTask = await ref.putData(bytes);
    return await uploadTask.ref.getDownloadURL();
  }
}

@riverpod
StorageRepository storageRepository(Ref ref) {
  return StorageRepository(FirebaseStorage.instance);
}
