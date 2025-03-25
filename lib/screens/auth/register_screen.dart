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
        
        // Parse Firebase error messages
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'Email already in use';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Invalid email format';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'Password is too weak';
        } else if (e.toString().contains('operation-not-allowed')) {
          errorMessage = 'Email/password accounts are not enabled';
        } else {
          // Use a simpler error message for other errors
          errorMessage = 'Registration failed: ${e.toString().split(']').last.trim()}';
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
    return Scaffold(
      backgroundColor: Colors.black,
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
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    labelStyle: TextStyle(color: Colors.greenAccent),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.greenAccent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purpleAccent, width: 2),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) => _email = val.trim(),
                  validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    labelStyle: TextStyle(color: Colors.greenAccent),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.greenAccent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purpleAccent, width: 2),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  onChanged: (val) => _password = val,
                  validator: (val) => val!.length < 6 ? 'Password must be 6+ chars' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                    labelStyle: TextStyle(color: Colors.greenAccent),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.greenAccent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purpleAccent, width: 2),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  onChanged: (val) => _confirmPassword = val,
                  validator: (val) => val!.length < 6 ? 'Password must be 6+ chars' : null,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerWithEmailAndPassword,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('REGISTER', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : widget.onSwitchToLogin,
                  child: const Text(
                    'ALREADY HAVE AN ACCOUNT? SIGN IN',
                    style: TextStyle(color: Colors.pinkAccent),
                  ),
                ),
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
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