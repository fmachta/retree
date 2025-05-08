import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Delete user account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("No user logged in to delete.");
    }

    try {
      // Attempt to delete the user from Firebase Authentication
      await user.delete();
      print('Firebase Auth user deleted successfully.');

      // Optionally: Delete associated data (e.g., Firestore document)
      // It's good practice to handle potential errors here too
      try {
        final firestore = FirebaseFirestore.instance; // Get Firestore instance
        await firestore.collection('users').doc(user.uid).delete();
        print('Firestore user document deleted successfully.');
      } catch (firestoreError) {
        print('Error deleting Firestore user data: $firestoreError');
        // Decide how to handle this: maybe rethrow, maybe log, maybe ignore
        // For now, just printing the error. The Auth user is already deleted.
      }

    } on FirebaseAuthException catch (e) {
      print('Error deleting Firebase Auth user: ${e.code} - ${e.message}');
      if (e.code == 'requires-recent-login') {
        // This error means the user needs to re-authenticate before deletion.
        // You should prompt the user to log in again.
        // For simplicity here, we rethrow a specific exception or message.
        throw Exception(
            'This operation requires recent authentication. Please log out and log back in before deleting your account.');
      }
      // Rethrow other Firebase Auth exceptions
      rethrow;
    } catch (e) {
      print('An unexpected error occurred during account deletion: $e');
      // Rethrow general exceptions
      rethrow;
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