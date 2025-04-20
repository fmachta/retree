import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateUsernameScreen extends StatefulWidget {
  final User user; // Receive the logged-in user

  const CreateUsernameScreen({Key? key, required this.user}) : super(key: key);

  @override
  _CreateUsernameScreenState createState() => _CreateUsernameScreenState();
}

class _CreateUsernameScreenState extends State<CreateUsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _username = '';
  String _error = '';
  bool _isLoading = false;

  Future<void> _saveUsername() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      try {
        // Check if username already exists (case-insensitive check for uniqueness)
        final querySnapshot = await _firestore
            .collection('users')
            .where('username_lowercase', isEqualTo: _username.toLowerCase())
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
           setState(() {
             _error = 'Username already taken. Please choose another.';
             _isLoading = false;
           });
           return; // Stop execution if username exists
        }

        // Username is unique, save it
        await _firestore.collection('users').doc(widget.user.uid).set({
          'username': _username,
          'username_lowercase': _username.toLowerCase(), // Store lowercase for querying
          'email': widget.user.email, // Optionally store email too
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // Use merge: true in case the doc exists but lacks username

        // Username saved successfully.
        // The AuthWrapper should now detect the logged-in user and navigate
        // to the main app screen automatically. No explicit navigation needed here.
        // If navigation doesn't happen automatically, you might need to add:
        // Navigator.of(context).pushReplacementNamed('/home'); // Or your main route

      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Error saving username: ${e.toString()}';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
                  'CHOOSE YOUR USERNAME',
                  style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This will be displayed on leaderboards.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                   textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person, color: theme.colorScheme.primary),
                  ),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  onChanged: (val) => _username = val.trim(),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (val.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (val.length > 15) {
                      return 'Username cannot exceed 15 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(val)) {
                      return 'Only letters, numbers, and underscores allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveUsername,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                            ),
                          )
                        : const Text('SAVE USERNAME & CONTINUE'),
                  ),
                ),
                 if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _error,
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
