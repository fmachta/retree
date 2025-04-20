import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuthException
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  
  const RegisterScreen({
    Key? key,
    required this.onSwitchToLogin,
  }) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _error = '';
  bool _isLoading = false;
  bool _isPasswordVisible = false; // State for password visibility
  bool _isConfirmPasswordVisible = false; // State for confirm password visibility

  void _registerWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      if (_password != _confirmPassword) {
        setState(() {
          _error = 'Passwords do not match';
        });
        return;
      }
      
      setState(() {
        _isLoading = true;
        _error = '';
      });

      try {
        await _authService.registerWithEmailAndPassword(_email, _password);
        // Registration successful
      } catch (e) {
        String errorMessage = 'Registration failed';
        
        // Use FirebaseAuthException codes for reliable error handling
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'email-already-in-use':
              errorMessage = 'This email is already registered. Try logging in.';
              break;
            case 'invalid-email':
              errorMessage = 'The email address is badly formatted.';
              break;
            case 'weak-password':
              errorMessage = 'Password is too weak. Please use a stronger password.';
              break;
            case 'operation-not-allowed':
              errorMessage = 'Email/password sign-up is not enabled.';
              break;
            default:
              errorMessage = 'An unexpected error occurred. Please try again.';
          }
        } else {
          // Generic error for non-Firebase exceptions
          errorMessage = 'Registration failed. Please check your connection.';
        }
        
        setState(() {
          _error = errorMessage;
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data

    return Scaffold(
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
                  'CREATE ACCOUNT',
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
                      return 'Please enter an email';
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
                      return 'Please enter a password';
                    }
                    if (val.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary), // Use theme color
                     // Add suffix icon to toggle confirm password visibility
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  style: TextStyle(color: theme.colorScheme.onSurface), // Use theme text style
                  obscureText: !_isConfirmPasswordVisible, // Control visibility
                  onChanged: (val) => _confirmPassword = val,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (val != _password) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity, // Make button take full width
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerWithEmailAndPassword,
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
                        : const Text('REGISTER'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : widget.onSwitchToLogin,
                   // Use theme for text button styling
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.secondary, // Use theme color
                  ),
                  child: const Text('ALREADY HAVE AN ACCOUNT? SIGN IN'),
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
