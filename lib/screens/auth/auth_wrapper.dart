import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../start_screen/startscreen.dart';
import '../../services/auth_service.dart';

class AuthWrapper extends StatefulWidget {
  final bool requireAuth;
  final bool firebaseInitialized;
  
  const AuthWrapper({
    Key? key,
    this.requireAuth = false,
    this.firebaseInitialized = true,
  }) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _showLogin = true;

  void _toggleView() {
    setState(() {
      _showLogin = !_showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Skip authentication if not required or if Firebase is not initialized
    if (!widget.requireAuth || !widget.firebaseInitialized) {
      return const StartScreen();
    }
    
    try {
      return StreamBuilder<User?>(
        stream: _authService.userStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("Stream error: ${snapshot.error}");
            // On error, redirect to start screen
            return const StartScreen();
          }
          
          if (snapshot.connectionState == ConnectionState.active) {
            final User? user = snapshot.data;
            if (user == null) {
              // User is not signed in
              return _showLogin
                  ? LoginScreen(onSwitchToRegister: _toggleView)
                  : RegisterScreen(onSwitchToLogin: _toggleView);
            }
            // User is signed in
            return const StartScreen();
          }
          
          // Connecting to stream
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    } catch (e) {
      print("Auth wrapper exception: $e");
      // Fallback to start screen if anything goes wrong
      return const StartScreen();
    }
  }
} 