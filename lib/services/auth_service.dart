// services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      print('📝 Creating user with email: $email');

      // Create user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // ✅ CRITICAL: Set display name
        print('📝 Setting display name to: "$name"');
        await user.updateDisplayName(name);

        // Force reload
        await user.reload();
        user = _auth.currentUser;

        print('✅ Display name after update: "${user?.displayName}"');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('❌ Error: ${e.code}');
      throw Exception(_handleError(e));
    }
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await result.user?.reload();
      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  String _handleError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'user-not-found':
        return 'No user found';
      case 'wrong-password':
        return 'Wrong password';
      default:
        return 'Authentication failed';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}