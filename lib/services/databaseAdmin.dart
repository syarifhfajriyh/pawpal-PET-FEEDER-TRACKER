import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseAdmin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add history log for a user
  Future<void> addUserHistory(String username, String action) async {
    try {
      await _db.collection('admin_history').add({
        'username': username,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("History added for $username action: $action");
    } catch (e) {
      print("Failed to add history: $e");
    }
  }

  // Get all users
  Future<QuerySnapshot> getAllUsers() async {
    try {
      return await _db.collection('paw_user').get();
    } catch (e) {
      print("Failed to get users: $e");
      rethrow;
    }
  }

  // Delete a user by uid
  Future<void> deleteUser(String uid) async {
    try {
      await _db.collection('paw_user').doc(uid).delete();
      print("User $uid deleted.");
    } catch (e) {
      print("Failed to delete user: $e");
    }
  }

  // Update user role
  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _db
          .collection('paw_user')
          .doc(uid)
          .set({'role': role}, SetOptions(merge: true));
      print("User $uid role updated to $role.");
    } catch (e) {
      print("Failed to update role: $e");
    }
  }

  // Update a single field of a user
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

  // Get all history logs
  Future<QuerySnapshot> getAllHistory() async {
    try {
      return await _db
          .collection('admin_history')
          .orderBy('timestamp', descending: true)
          .get();
    } catch (e) {
      print("Failed to get history: $e");
      rethrow;
    }
  }
}
