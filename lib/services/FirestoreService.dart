import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get users =>
      _db.collection('users');

  /// Ensure user doc exists/updated at login. Role is 0=user, 1=admin.
  Future<void> upsertUserFromAuth(User user, {int role = 0}) async {
    final ref = users.doc(user.uid);
    final now = FieldValue.serverTimestamp();
    final snap = await ref.get();

    final data = {
      'email': user.email,
      'displayName': user.displayName ?? user.email?.split('@').first,
      'avatarUrl': user.photoURL ?? '',
      'emailVerified': user.emailVerified,
      // If doc exists, keep existing role; else use provided default (0)
      'role': snap.exists ? (snap.data()?['role'] ?? role) : role,
      'lastSeen': now,
      if (!snap.exists) 'createdAt': now,
    };

    await ref.set(data, SetOptions(merge: true));
  }

  /// Stream a single user document by uid
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUser(String uid) {
    return users.doc(uid).snapshots();
  }

  Future<void> updateMyProfile({
    required String uid,
    String? displayName,
    String? username,
    String? email,
    String? bio,
    bool? notifEnabled,
    String? avatarUrl,
  }) async {
    await users.doc(uid).set({
      if (displayName != null) 'displayName': displayName,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (bio != null) 'bio': bio,
      if (notifEnabled != null) 'notifEnabled': notifEnabled,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllUsers() {
    return users.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> updateUserByAdmin({
    required String uid,
    String? displayName,
    String? avatarUrl,
    int? role,
  }) async {
    await users.doc(uid).set({
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (role != null) 'role': role,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteUserDocByAdmin(String uid) async {
    await users.doc(uid).delete();
  }
}
