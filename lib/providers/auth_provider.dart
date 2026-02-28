// providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isOffline = false;
  String? _cachedName; // Cache name locally

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isOffline => _isOffline;

  // ✅ FIXED: Priority order for getting name
  String get fullName {
    // Priority 1: Check if we have cached name
    if (_cachedName != null && _cachedName!.isNotEmpty) {
      return _cachedName!;
    }

    // Priority 2: Firebase Auth display name
    if (_user?.displayName != null && _user!.displayName!.isNotEmpty) {
      _cachedName = _user!.displayName;
      return _user!.displayName!;
    }

    // Priority 3: Email username (temporary fix)
    if (_user?.email != null && _user!.email!.isNotEmpty) {
      String emailName = _user!.email!.split('@')[0];
      _cachedName = emailName;
      return emailName;
    }

    // Final fallback
    return 'User';
  }

  String get firstName {
    String name = fullName;
    if (name != 'User' && name.isNotEmpty) {
      return name.split(' ').first;
    }
    return 'User';
  }

  String get email => _user?.email ?? 'user@example.com';

  AuthProvider() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      print('🔥 Auth state changed:');
      print('   - UID: ${firebaseUser?.uid}');
      print('   - Email: ${firebaseUser?.email}');
      print('   - Auth Display Name: ${firebaseUser?.displayName ?? "NOT SET"}');

      _user = firebaseUser;

      if (firebaseUser != null) {
        // ✅ CRITICAL FIX: If no display name, set it from email
        if (firebaseUser.displayName == null || firebaseUser.displayName!.isEmpty) {
          await _fixMissingDisplayName();
        } else {
          // Cache the name
          _cachedName = firebaseUser.displayName;
        }

        // Try to get from Firestore in background
        _loadFromFirestore();

        // Check connection
        await _checkConnection();
      }

      notifyListeners();
    });
  }

  // ✅ NEW: Fix missing display name by setting from email
  Future<void> _fixMissingDisplayName() async {
    if (_user == null) return;

    try {
      // Get name from email
      String emailName = _user!.email!.split('@')[0];

      print('📝 FIXING: Setting display name to "$emailName" from email');

      // Update Firebase Auth
      await _user!.updateDisplayName(emailName);
      await _user!.reload();

      // Refresh user
      _user = FirebaseAuth.instance.currentUser;
      _cachedName = emailName;

      print('✅ FIXED: Auth display name is now "${_user!.displayName}"');

      // Also try to save to Firestore
      _saveToFirestore(emailName);

      notifyListeners();
    } catch (e) {
      print('❌ Failed to fix display name: $e');
    }
  }

  // ✅ Save to Firestore
  Future<void> _saveToFirestore(String name) async {
    if (_user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'name': name,
        'email': _user!.email,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Saved name to Firestore: $name');
    } catch (e) {
      print('⚠️ Could not save to Firestore: $e');
    }
  }

  // ✅ Load from Firestore
  Future<void> _loadFromFirestore() async {
    if (_user == null) return;

    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (doc.exists && doc.data() != null && doc.data()!['name'] != null) {
        String firestoreName = doc.data()!['name'] as String;

        // If Firestore has a different name, update Auth
        if (_user!.displayName != firestoreName) {
          await _user!.updateDisplayName(firestoreName);
          await _user!.reload();
          _user = FirebaseAuth.instance.currentUser;
          _cachedName = firestoreName;
          print('✅ Updated Auth from Firestore: $firestoreName');
        }
      }
    } catch (e) {
      // Silently fail - we'll use email name
    }
  }

  Future<void> _checkConnection() async {
    try {
      await FirebaseFirestore.instance.collection('test').doc('test').get();
      _isOffline = false;
    } catch (e) {
      _isOffline = true;
    }
    print('📡 Connection: ${_isOffline ? "Offline" : "Online"}');
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📝 Sign up with name: "$name"');

      final user = await _authService.signUp(
        name: name,
        email: email,
        password: password,
      );

      if (user != null) {
        _user = user;
        _cachedName = name;

        // Try to save to Firestore
        _saveToFirestore(name);
      }

      return user != null;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signIn(
        email: email,
        password: password,
      );

      if (user != null) {
        _user = user;

        // If no display name, fix it
        if (user.displayName == null || user.displayName!.isEmpty) {
          await _fixMissingDisplayName();
        } else {
          _cachedName = user.displayName;
        }
      }

      return user != null;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUserDataFromFirestore() async {
    await _loadFromFirestore();
    await _checkConnection();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _cachedName = null;
    _isOffline = false;
    notifyListeners();
  }
}