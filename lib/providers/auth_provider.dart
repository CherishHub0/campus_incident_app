import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { loading, signedOut, needsVerification, ready }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service) {
    _userSub = _service.userChanges.listen(_onUser);
  }

  final AuthService _service;
  StreamSubscription<User?>? _userSub;
  StreamSubscription<AppUser?>? _profileSub;

  User? _user;
  AppUser? _profile;
  String? _profileUid;
  bool _initialised = false;
  bool busy = false;

  AuthStatus get status {
    if (!_initialised) return AuthStatus.loading;
    if (_user == null) return AuthStatus.signedOut;
    if (!_user!.emailVerified) return AuthStatus.needsVerification;
    if (_profile == null) return AuthStatus.loading;
    return AuthStatus.ready;
  }

  String? get uid => _user?.uid;
  String? get readyUid => status == AuthStatus.ready ? _user!.uid : null;
  String? get email => _user?.email;
  bool get isStaff =>
      roleForEmail(_user?.email ?? '') == 'staff' || (_profile?.isStaff ?? false);
  String get role => isStaff ? 'staff' : (_profile?.role ?? 'student');
  String get displayName {
    final profileName = _profile?.fullName.trim();
    if (profileName != null && profileName.isNotEmpty && profileName != 'Student') {
      return profileName;
    }
    final authName = _user?.displayName?.trim();
    if (authName != null && authName.isNotEmpty) return authName;
    final emailName = _user?.email?.split('@').first.trim();
    if (emailName != null && emailName.isNotEmpty) return emailName;
    return isStaff ? 'Staff' : 'Student';
  }

  void _onUser(User? u) {
    _user = u;
    _initialised = true;
    if (u == null) {
      _profileSub?.cancel();
      _profileSub = null;
      _profile = null;
      _profileUid = null;
    } else if (_profileUid != u.uid) {
      _profileSub?.cancel();
      _profile = null;
      _profileUid = u.uid;
      _profileSub = _service.watchProfile(u.uid).listen((p) {
        _profile = p ??
            AppUser(
              uid: u.uid,
              fullName: u.displayName ?? 'Student',
              email: u.email ?? '',
              role: roleForEmail(u.email ?? '') ?? 'student',
            );
        notifyListeners();
      }, onError: (_) {
        _profile = AppUser(
          uid: u.uid,
          fullName: u.displayName ?? 'Student',
          email: u.email ?? '',
          role: roleForEmail(u.email ?? '') ?? 'student',
        );
        notifyListeners();
      });
    }
    notifyListeners();
  }

  /// Returns an error message, or null on success.
  Future<String?> signIn(String email, String password) =>
      _run(() => _service.signIn(email.trim(), password));

  Future<String?> register(String name, String email, String password) async {
    if (!isAllowedEmail(email)) {
      return 'Please use your ALU email '
          '(${allowedEmailDomains.map((d) => '@$d').join(' or ')}).';
    }
    return _run(() => _service.register(
          fullName: name.trim(),
          email: email.trim().toLowerCase(),
          password: password,
        ));
  }

  Future<void> signOut() => _service.signOut();

  Future<String?> resendVerification() =>
      _run(() => _service.sendVerification());

  Future<String?> sendPasswordReset(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!isAllowedEmail(normalizedEmail)) {
      return 'Please use your ALU email '
          '(${allowedEmailDomains.map((d) => '@$d').join(' or ')}).';
    }

    busy = true;
    notifyListeners();
    try {
      await _service.sendPasswordReset(normalizedEmail);
      return null;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found') return null;
      return _message(error.code);
    } catch (_) {
      return 'Could not send the password reset email. Please try again.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Called by the verify screen; returns true once the email is verified.
  Future<bool> checkVerified() async {
    final ok = await _service.refreshVerification();
    _user = FirebaseAuth.instance.currentUser;
    notifyListeners();
    return ok;
  }

  Future<String?> _run(Future<void> Function() action) async {
    busy = true;
    notifyListeners();
    try {
      await action();
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e.code);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  String _message(String code) => switch (code) {
        'invalid-email' => 'That email address is not valid.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Incorrect email or password.',
        'email-already-in-use' => 'An account with this email already exists.',
        'weak-password' => 'Password must be at least 6 characters.',
        'too-many-requests' => 'Too many attempts. Please wait and try again.',
        'network-request-failed' => 'No internet connection.',
        _ => 'Authentication failed ($code).',
      };

  @override
  void dispose() {
    _userSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
