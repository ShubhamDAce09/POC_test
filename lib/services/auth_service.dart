import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_profile.dart';
import '../utils/email.dart';
import 'analytics_service.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    required SharedPreferences prefs,
    required this.firebaseReady,
    required AnalyticsService analytics,
  })  : _prefs = prefs,
        _analytics = analytics;

  final SharedPreferences _prefs;
  final AnalyticsService _analytics;
  final bool firebaseReady;
  final _localController = StreamController<StudentProfile?>.broadcast();

  static const _emailKey = 'demo_user_email';
  static const _uidKey = 'demo_user_uid';

  Stream<StudentProfile?> authState() {
    if (firebaseReady) {
      return FirebaseAuth.instance.authStateChanges().map(_fromFirebase);
    }
    return Stream<StudentProfile?>.multi((listener) {
      listener.add(_readLocal());
      listener.addStream(_localController.stream);
    });
  }

  StudentProfile? currentUser() {
    if (firebaseReady) {
      return _fromFirebase(FirebaseAuth.instance.currentUser);
    }
    return _readLocal();
  }

  Future<StudentProfile> signIn({
    required String email,
    required String password,
  }) async {
    _assertInstituteEmail(email);
    if (password.length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }

    if (firebaseReady) {
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: normalizeEmail(email),
          password: password,
        );
        final profile = _fromFirebase(credential.user);
        if (profile == null) {
          throw AuthException('Sign-in succeeded but no user was returned.');
        }
        await _analytics.logLogin(method: 'password');
        return profile;
      } on FirebaseAuthException catch (error) {
        throw AuthException(_mapFirebase(error));
      }
    }

    final profile = StudentProfile(
      uid: 'local-${normalizeEmail(email).hashCode}',
      email: normalizeEmail(email),
    );
    await _persistLocal(profile);
    _localController.add(profile);
    await _analytics.logLogin(method: 'demo');
    return profile;
  }

  Future<StudentProfile> register({
    required String email,
    required String password,
  }) async {
    _assertInstituteEmail(email);
    if (password.length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }

    if (firebaseReady) {
      try {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: normalizeEmail(email),
          password: password,
        );
        final profile = _fromFirebase(credential.user);
        if (profile == null) {
          throw AuthException('Registration succeeded but no user was returned.');
        }
        await _analytics.logLogin(method: 'register');
        return profile;
      } on FirebaseAuthException catch (error) {
        throw AuthException(_mapFirebase(error));
      }
    }

    return signIn(email: email, password: password);
  }

  Future<void> signOut() async {
    if (firebaseReady) {
      await FirebaseAuth.instance.signOut();
    }
    await _prefs.remove(_emailKey);
    await _prefs.remove(_uidKey);
    _localController.add(null);
  }

  void _assertInstituteEmail(String email) {
    if (!isInstituteEmail(email)) {
      throw AuthException(
        'Use your institute email ending with @iimshillong.ac.in',
      );
    }
  }

  StudentProfile? _fromFirebase(User? user) {
    if (user == null || user.email == null) return null;
    if (!isInstituteEmail(user.email!)) {
      unawaited(FirebaseAuth.instance.signOut());
      return null;
    }
    return StudentProfile(
      uid: user.uid,
      email: normalizeEmail(user.email!),
      displayName: user.displayName ?? '',
    );
  }

  StudentProfile? _readLocal() {
    final email = _prefs.getString(_emailKey);
    final uid = _prefs.getString(_uidKey);
    if (email == null || uid == null) return null;
    return StudentProfile(uid: uid, email: email);
  }

  Future<void> _persistLocal(StudentProfile profile) async {
    await _prefs.setString(_emailKey, profile.email);
    await _prefs.setString(_uidKey, profile.uid);
  }

  String _mapFirebase(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'That institute email is already registered.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      default:
        debugPrint('FirebaseAuthException ${error.code}: ${error.message}');
        return error.message ?? 'Authentication failed.';
    }
  }
}
