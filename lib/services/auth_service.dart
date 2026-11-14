import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants.dart';
import '../models/app_user.dart';

/// Thin wrapper around Firebase Auth + the `users` collection.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get userChanges => _auth.userChanges();

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final role = roleForEmail(email);
    if (role == null) {
      throw ArgumentError.value(email, 'email', 'Email domain is not allowed.');
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(fullName);
    await _db.collection('users').doc(user.uid).set({
      'fullName': fullName,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await user.sendEmailVerification();
  }

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  Future<void> sendVerification() async =>
      _auth.currentUser?.sendEmailVerification();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  /// Reloads the user and refreshes the ID token once verified so that
  /// security rules (`email_verified`) see the new value.
  Future<bool> refreshVerification() async {
    final u = _auth.currentUser;
    if (u == null) return false;
    await u.reload();
    final fresh = _auth.currentUser;
    if (fresh?.emailVerified == true) {
      await fresh!.getIdToken(true);
      return true;
    }
    return false;
  }

  Stream<AppUser?> watchProfile(String uid) =>
      _db.collection('users').doc(uid).snapshots().map(
            (s) => s.exists ? AppUser.fromMap(uid, s.data()!) : null,
          );
}
