import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Auth change user stream
  Stream<User?> get userStream => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in anonymously
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print('Error signing in anonymously: $e');
      rethrow; // Rethrow to allow handling in UI
    }
  }

  // Register with email & password
  Future<UserCredential?> registerWithEmailAndPassword(String email, String password) async {
    try {
      // Create user with email and password
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Return the UserCredential directly
      return result;
    } catch (e) {
      print('Error registering with email and password: $e');
      rethrow; // Rethrow to allow handling in UI
    }
  }

  // Sign in with email & password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in with email and password: $e');
      rethrow; // Rethrow to allow handling in UI
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow; // Rethrow to allow handling in UI
    }
  }

  // Check if auth is initialized and available
  bool isAuthAvailable() {
    try {
      // This will throw an exception if Firebase Auth is not properly initialized
      _auth.authStateChanges().listen((user) {});
      return true;
    } catch (e) {
      print('Firebase Auth is not available: $e');
      return false;
    }
  }
} 