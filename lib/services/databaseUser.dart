import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseUser {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get current user's document by uid
  Future<DocumentSnapshot> getUser(String uid) async {
    try {
      return await _db.collection('paw_user').doc(uid).get();
    } catch (e) {
      print("Failed to get user: $e");
      rethrow;
    }
  }

  // Update user profile (auto create if not exists)
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _db
          .collection('paw_user')
          .doc(uid)
          .set(data, SetOptions(merge: true));
      print("User $uid profile updated.");
    } catch (e) {
      print("Failed to update profile: $e");
    }
  }

  // Update a single field (this is needed for main.dart)
  Future<void> updateUserField(String uid, String field, dynamic value) async {
    try {
      await _db
          .collection('paw_user')
          .doc(uid)
          .set({field: value}, SetOptions(merge: true));
      print("User $uid field '$field' updated.");
    } catch (e) {
      print("Failed to update field: $e");
    }
  }

  // Add action log for this user
  Future<void> addUserAction(String uid, String action) async {
    try {
      await _db.collection('user_history').add({
        'uid': uid,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Failed to add user action: $e");
    }
  }

  // Get user history by uid
  Future<QuerySnapshot> getUserHistory(String uid) async {
    try {
      return await _db
          .collection('user_history')
          .where('uid', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .get();
    } catch (e) {
      print("Failed to get user history: $e");
      rethrow;
    }
  }

  // Check user role
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('paw_user').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>?)?['role'] as String?;
      }
      return null;
    } catch (e) {
      print("Failed to get user role: $e");
      return null;
    }
  }
}
