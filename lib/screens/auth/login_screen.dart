import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

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

  void _signInWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      try {
        await _authService.signInWithEmailAndPassword(_email, _password);
        // Login successful
      } catch (e) {
        String errorMessage = 'Login failed';
        
        // Parse Firebase error messages
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'No user found with this email';
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = 'Incorrect password';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Invalid email format';
        } else if (e.toString().contains('user-disabled')) {
          errorMessage = 'This account has been disabled';
        } else if (e.toString().contains('too-many-requests')) {
          errorMessage = 'Too many failed login attempts. Try again later';
        } else {
          // Use a simpler error message for other errors
          errorMessage = 'Login failed: ${e.toString().split(']').last.trim()}';
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

  void _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await _authService.signInAnonymously();
      // Anonymous login successful
    } catch (e) {
      String errorMessage = 'Guest sign-in failed';
      
      if (e.toString().contains('operation-not-allowed')) {
        errorMessage = 'Anonymous sign-in is not enabled';
      } else {
        // Use a simpler error message for other errors
        errorMessage = 'Guest sign-in failed: ${e.toString().split(']').last.trim()}';
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
                  'RETREE',
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
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithEmailAndPassword,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('SIGN IN', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : _signInAnonymously,
                  child: const Text(
                    'PLAY AS GUEST',
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isLoading ? null : widget.onSwitchToRegister,
                  child: const Text(
                    'CREATE ACCOUNT',
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