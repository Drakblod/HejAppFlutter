import 'package:firebase_database/firebase_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import '../models/group.dart';
import '../models/chat_message.dart';
import '../models/postit.dart';
import '../models/user_profile.dart';
import '../models/group_member.dart';
import '../models/shared_file.dart';

part 'database_repository.g.dart';

class DatabaseRepository {
  final FirebaseDatabase _db;

  DatabaseRepository(this._db);

  // --- Users ---

  Future<void> createUserProfile(UserProfile profile) async {
    await _db.ref('profiles/${profile.uid}').set(profile.toJson());
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final snapshot = await _db.ref('users/$uid').get();
    if (!snapshot.exists) return null;
    return UserProfile.fromJson(uid, snapshot.value as Map<dynamic, dynamic>);
  }

  // --- Groups ---
  
  Stream<List<String>> streamUserGroupIds(String uid) {
    return _db.ref('userGroups/$uid').onValue.map((event) {
      final map = event.snapshot.value as Map<dynamic, dynamic>?;
      if (map == null) return [];
      return map.keys.map((k) => k.toString()).toList();
    });
  }

  Future<Group?> getGroupMeta(String groupId) async {
    final snapshot = await _db.ref('groups/$groupId').get();
    if (!snapshot.exists) return null;
    return Group.fromJson(groupId, snapshot.value as Map<dynamic, dynamic>);
  }

  Future<void> createGroup({
    required String name,
    required String ownerId,
    String theme = 'Default',
    String icon = '👥',
  }) async {
    final groupId = _db.ref('groups').push().key!;
    final now = DateTime.now().millisecondsSinceEpoch;

    final groupData = {
      'name': name,
      'theme': theme,
      'icon': icon,
      'ownerId': ownerId,
      'createdAt': now,
    };

    await _db.ref('groups/$groupId').set(groupData);
    await _db.ref('memberships/$groupId/$ownerId').set({
      'role': 'owner',
      'joinedAt': now,
    });
    await _db.ref('userGroups/$ownerId/$groupId').set(true);
  }

  // --- Messages ---

  Stream<List<ChatMessage>> streamMessages(String groupId, {int limit = 50}) {
    return _db.ref('messages/$groupId')
        .orderByKey()
        .limitToLast(limit)
        .onValue
        .map((event) {
      final map = event.snapshot.value as Map<dynamic, dynamic>?;
      if (map == null) return [];
      
      final messages = <ChatMessage>[];
      map.forEach((key, value) {
        messages.add(ChatMessage.fromJson(key.toString(), value as Map<dynamic, dynamic>));
      });
      
      // Sort by timestamp
      messages.sort((a, b) => a.ts.compareTo(b.ts));
      return messages;
    });
  }

  Future<void> sendMessage(ChatMessage message) async {
    await _db.ref('messages/${message.groupId}').push().set(message.toJson());
  }

  // --- Post-Its ---

  Stream<List<PostIt>> streamPostIts(String groupId) {
    return _db.ref('postits/$groupId').onValue.map((event) {
      final map = event.snapshot.value as Map<dynamic, dynamic>?;
      if (map == null) return [];
      
      final items = <PostIt>[];
      map.forEach((key, value) {
        items.add(PostIt.fromJson(key.toString(), value as Map<dynamic, dynamic>));
      });
      return items;
    });
  }

  Future<void> savePostIt(PostIt postIt) async {
    await _db.ref('postits/${postIt.groupId}/${postIt.id}').set(postIt.toJson());
  }

  Future<void> deletePostIt(String groupId, String postItId) async {
    print('[DELETE_DEBUG] Repository: Attempting to delete postits/$groupId/$postItId');
    try {
      await _db.ref('postits/$groupId/$postItId').remove();
      print('[DELETE_DEBUG] Repository: Successfully removed.');
    } catch (e) {
      print('[DELETE_DEBUG] Repository ERROR: $e');
      rethrow;
    }
  }

  String generatePostItId(String groupId) {
    return _db.ref('postits/$groupId').push().key!;
  }

  // --- Shared Files ---

  Stream<List<SharedFile>> streamSharedFiles(String groupId) {
    return _db.ref('files/$groupId').onValue.map((event) {
      final map = event.snapshot.value as Map<dynamic, dynamic>?;
      if (map == null) return [];

      final items = <SharedFile>[];
      map.forEach((key, value) {
        items.add(SharedFile.fromJson(key.toString(), value as Map<dynamic, dynamic>));
      });
      
      // Sort by timestamp descending
      items.sort((a, b) => b.ts.compareTo(a.ts));
      return items;
    });
  }

  Future<void> saveSharedFileMetadata(SharedFile file) async {
    await _db.ref('files/${file.groupId}/${file.id}').set(file.toJson());
  }

  String generateFileId(String groupId) {
    return _db.ref('files/$groupId').push().key!;
  }

  // --- Profiles ---

  Stream<UserProfile?> streamProfile(String uid) {
    return _db.ref('profiles/$uid').onValue.switchMap((event) {
      final map = event.snapshot.value as Map<dynamic, dynamic>?;
      if (map != null) {
        return Stream.value(UserProfile.fromJson(uid, map));
      }
      
      // Fallback: Check legacy path if profiles node is empty
      return _db.ref('users/$uid').onValue.map((legacyEvent) {
        final legacyMap = legacyEvent.snapshot.value as Map<dynamic, dynamic>?;
        if (legacyMap == null) return null;
        return UserProfile.fromJson(uid, legacyMap);
      });
    });
  }

  Future<UserProfile?> getProfile(String uid) async {
    // 1. Check standardized /profiles/ node
    final snapshot = await _db.ref('profiles/$uid').get();
    if (snapshot.exists) {
      return UserProfile.fromJson(uid, snapshot.value as Map<dynamic, dynamic>);
    }

    // 2. Fallback to legacy /users/ node
    final legacySnapshot = await _db.ref('users/$uid').get();
    if (legacySnapshot.exists) {
      final profile = UserProfile.fromJson(uid, legacySnapshot.value as Map<dynamic, dynamic>);
      // Self-heal: Move to /profiles/ so next time is faster
      await _db.ref('profiles/$uid').set(profile.toJson());
      return profile;
    }

    return null;
  }

  Future<void> updateProfile(UserProfile profile, {String? oldUsername}) async {
    final batch = <String, dynamic>{};
    
    // 1. Update Profile
    batch['profiles/${profile.uid}'] = profile.toJson();
    
    // 2. Handle Username Reservation if changed
    final newUsername = profile.username.trim().toLowerCase();
    if (oldUsername != null && oldUsername.toLowerCase() != newUsername) {
      batch['usernames/$newUsername'] = profile.uid;
      // We don't delete the old one in a batch set, we might need a separate delete?
      // Actually Firebase set(null) deletes.
      batch['usernames/${oldUsername.toLowerCase()}'] = null;
    } else if (oldUsername == null) {
      // First time setting
      batch['usernames/$newUsername'] = profile.uid;
    }
    
    await _db.ref().update(batch);
  }

  Future<bool> isUsernameAvailable(String username) async {
    final cleaned = username.trim().toLowerCase();
    if (cleaned.isEmpty) return false;
    
    final snapshot = await _db.ref('usernames/$cleaned').get();
    return !snapshot.exists;
  }

  Future<void> updateGroupMeta(String groupId, Map<String, dynamic> data) async {
    await _db.ref('groups/$groupId').update(data);
  }

  Stream<List<GroupMember>> streamMembers(String groupId) {
    return _db.ref('memberships/$groupId').onValue.map((event) {
      final map = event.snapshot.value as Map<dynamic, dynamic>?;
      if (map == null) return [];
      
      return map.entries.map((e) {
        return GroupMember.fromJson(e.key.toString(), e.value as Map<dynamic, dynamic>);
      }).toList();
    });
  }

  Future<void> removeMember(String groupId, String userId) async {
    final batch = <String, dynamic>{};
    batch['memberships/$groupId/$userId'] = null;
    batch['userGroups/$userId/$groupId'] = null;
    await _db.ref().update(batch);
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    // Logic is the same as remove, but maybe we add a 'leftAt' log later
    await removeMember(groupId, userId);
  }

  Future<void> deleteGroup(String groupId) async {
     // This is a heavy operation, would normally be a Cloud Function
     // But for now, we'll just clear the main nodes
     final batch = <String, dynamic>{};
     batch['groups/$groupId'] = null;
     batch['memberships/$groupId'] = null;
     batch['messages/$groupId'] = null;
     batch['postits/$groupId'] = null;
     // Note: we can't easily clear userGroups/$userId/$groupId for all users without knowing them
     // So we'd need to fetch them first or use a Cloud Function.
     await _db.ref().update(batch);
  }

  Future<void> joinGroup(String groupId, String userId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = <String, dynamic>{};

    batch['memberships/$groupId/$userId'] = {
      'role': 'member',
      'joinedAt': now,
    };
    batch['userGroups/$userId/$groupId'] = true;

    await _db.ref().update(batch);
  }

  Future<bool> groupExists(String groupId) async {
    if (groupId.isEmpty) return false;
    final snapshot = await _db.ref('groups/$groupId').get();
    return snapshot.exists;
  }
}

@riverpod
DatabaseRepository databaseRepository(Ref ref) {
  return DatabaseRepository(FirebaseDatabase.instance);
}
