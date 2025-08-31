import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> reauthWithPassword(String email, String password) async {
    final cred = EmailAuthProvider.credential(email: email, password: password);
    await _auth.currentUser!.reauthenticateWithCredential(cred);
  }

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser!.updateDisplayName(name);
  }

  Future<void> updatePhotoUrl(String url) async {
    await _auth.currentUser!.updatePhotoURL(url);
  }

  Future<void> updateEmail(String newEmail) async {
    await _auth.currentUser!.updateEmail(newEmail);
  }

  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser!.updatePassword(newPassword);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
