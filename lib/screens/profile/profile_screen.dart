import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/highscore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final HighScoreService _highScoreService = HighScoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  
  String _username = '';
  Map<String, dynamic>? _userScores;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _savedUsername;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      
      if (user != null) {
        // Get user document
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _savedUsername = userData['username'] as String?;
            _username = _savedUsername ?? user.email ?? 'Anonymous Player';
          });
        } else {
          setState(() {
            _username = user.email ?? 'Anonymous Player';
          });
        }
        
        // Get user scores
        final scores = await _highScoreService.getUserHighScores();
        setState(() {
          _userScores = scores;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUsername() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      
      try {
        final user = _authService.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'username': _username,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
          setState(() {
            _savedUsername = _username;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username updated successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating username: $e')),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple[900],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.greenAccent, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.greenAccent,
                          blurRadius: 5,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar placeholder
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.greenAccent,
                          child: Text(
                            _username.isNotEmpty ? _username[0].toUpperCase() : 'A',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[900],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Email display
                        Text(
                          _authService.currentUser?.email ?? 'Anonymous',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Username form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                initialValue: _username,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                  labelStyle: TextStyle(color: Colors.greenAccent),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.greenAccent),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.purpleAccent, width: 2),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                                onChanged: (val) => _username = val.trim(),
                                validator: (val) => val!.isEmpty 
                                    ? 'Username cannot be empty' 
                                    : (val.length < 3 ? 'Username must be at least 3 characters' : null),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _updateUsername,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    child: _isSaving
                                        ? const CircularProgressIndicator()
                                        : const Text('UPDATE USERNAME'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Personal high scores section
                  const Text(
                    'YOUR HIGH SCORES',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_userScores == null || _userScores!.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No scores yet. Start playing games to record your high scores!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  else
                    ...(_userScores!.entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${entry.value}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()),
                ],
              ),
            ),
    );
  }
} 