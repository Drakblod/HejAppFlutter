import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_repository.g.dart';

class StorageRepository {
  final FirebaseStorage _storage;

  StorageRepository(this._storage);

  Future<String> uploadChatPhoto({
    required String groupId,
    required File file,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref = _storage.ref().child('chat_photos').child(groupId).child(fileName);
    
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref = _storage.ref().child('profile_photos').child(uid).child(fileName);
    
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadGroupBackground({
    required String groupId,
    required File file,
  }) async {
    final fileName = 'bg_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref = _storage.ref().child('group_backgrounds').child(groupId).child(fileName);
    
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}

@riverpod
StorageRepository storageRepository(Ref ref) {
  return StorageRepository(FirebaseStorage.instance);
}
