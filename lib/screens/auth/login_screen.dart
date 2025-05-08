import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../../services/auth_service.dart';
import './create_username_screen.dart'; // Import the new screen (will be created next)
import '../start_screen/startscreen.dart'; // Import StartScreen

class LoginScreen extends StatefulWidget {
  final VoidCallback onSwitchToRegister;
  
  const LoginScreen({
    Key? key,
    required this.onSwitchToRegister,
  }) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  String _email = '';
  String _password = '';
  String _error = '';
  bool _isLoading = false;
  bool _isPasswordVisible = false; // State for password visibility

  void _signInWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      UserCredential? userCredential; // Store the credential
      try {
        userCredential = await _authService.signInWithEmailAndPassword(_email, _password);
        
        // Login successful, now check for username
        if (userCredential?.user != null && mounted) {
          final user = userCredential!.user!;
          final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
          final userDoc = await userDocRef.get();

          if (!userDoc.exists || userDoc.data()?['username'] == null) {
            // Username doesn't exist, navigate to create username screen
            // We replace the current route so the user can't go back to login
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => CreateUsernameScreen(user: user),
              ),
            );
            // Return here to prevent further state updates in this screen
            return; 
          }
          // If username exists, the AuthWrapper will handle navigation
        }
      } catch (e) {
        String errorMessage;
        // Log the error for debugging regardless of type
        print('Sign-in error: $e'); 

        // Use FirebaseAuthException codes for reliable error handling
        if (e is FirebaseAuthException) {
          errorMessage = 'Login failed'; // Default message
          switch (e.code) {
            case 'user-not-found':
            case 'wrong-password':
            case 'invalid-credential': // Covers general invalid credential issues
              errorMessage = 'Invalid email or password. Please try again.';
              break;
            case 'invalid-email':
              errorMessage = 'The email address is badly formatted.';
              break;
            case 'user-disabled':
              errorMessage = 'This account has been disabled.';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many sign-in attempts. Please try again later.';
              break;
            // Add other specific codes if needed
            default:
              // Provide a slightly more specific default for Firebase errors
              errorMessage = 'An unexpected sign-in error occurred. (Code: ${e.code})'; 
          }
        } else {
          // Generic error for non-Firebase exceptions (e.g., network issues)
          errorMessage = 'Login failed. Please check connection or try again.';
        }
        
        if (mounted) { // Check if widget is still in the tree
          setState(() {
            _error = errorMessage;
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await _authService.signInAnonymously();
      // Anonymous login successful
    } catch (e) {
      String errorMessage;
      if (e is FirebaseAuthException && e.code == 'operation-not-allowed') {
        errorMessage = 'Guest sign-in is not enabled for this app.';
      } else {
        errorMessage = 'Guest sign-in failed. Please try again later.';
      }
      
      if (mounted) {
        setState(() {
          _error = errorMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data

    return Scaffold(
      // Add an AppBar with a MANUAL back button
      appBar: AppBar(
        // Explicitly add a leading back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), 
          tooltip: 'Back to Menu',
          onPressed: () {
            // Navigate back to the StartScreen, replacing the current route
            // This assumes StartScreen is the main menu
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const StartScreen()),
            );
          },
        ),
        // Optional: Set title or make transparent
        title: const Text('Sign In'), // Example title
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // Remove shadow
        // Ensure back button icon color contrasts with background
        iconTheme: IconThemeData(color: theme.colorScheme.primary), 
        titleTextStyle: TextStyle( // Ensure title color contrasts
          color: theme.colorScheme.primary, 
          fontSize: 20, 
          fontWeight: FontWeight.bold
        ),
      ),
      // Use theme background color
      backgroundColor: theme.scaffoldBackgroundColor, 
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'RETREE',
                  // Use theme headline style
                  style: theme.textTheme.headlineLarge?.copyWith(color: theme.colorScheme.primary), 
                ),
                const SizedBox(height: 40),
                TextFormField(
                  // Use theme's input decoration
                  decoration: InputDecoration( 
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: theme.colorScheme.primary), // Use theme color
                  ),
                  // Use theme text style
                  style: TextStyle(color: theme.colorScheme.onSurface), 
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (val) => _email = val.trim(),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) {
                       return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: theme.colorScheme.primary), // Use theme color
                    // Add suffix icon to toggle password visibility
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  style: TextStyle(color: theme.colorScheme.onSurface), // Use theme text style
                  obscureText: !_isPasswordVisible, // Control visibility
                  onChanged: (val) => _password = val,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (val.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity, // Make button take full width
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithEmailAndPassword,
                    // Use theme for button styling
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: _isLoading
                        // Use theme's progress indicator color
                        ? SizedBox(
                            height: 24, // Consistent height for indicator
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                            ),
                          )
                        : const Text('SIGN IN'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : _signInAnonymously,
                  // Use theme for text button styling
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.secondary, // Use theme color
                  ),
                  child: const Text('PLAY AS GUEST'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => widget.onSwitchToRegister(),
                  child: Text(
                    'Register',
                    style: TextStyle(color: theme.colorScheme.secondary), // Use theme color
                  ),
                ),
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _error,
                      // Use theme error color
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 14), 
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
