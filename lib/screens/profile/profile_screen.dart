import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import intl for date formatting
import '../../services/auth_service.dart';
import '../../services/highscore_service.dart';
import '../auth/auth_wrapper.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final HighScoreService _highScoreService = HighScoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _username; // Store fetched username
  Timestamp? _createdAt; // Store account creation date
  Map<String, dynamic>? _userScores;
  bool _isLoadingProfile = true; // Separate loading state for profile data
  bool _isLoadingScores = true; // Separate loading state for scores

  // Controller and key for the change username dialog form
  final _usernameFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isSavingUsername = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProfile = true;
      _isLoadingScores = true;
    });

    final user = _authService.currentUser;
    if (user == null) {
      setState(() {
        _isLoadingProfile = false;
        _isLoadingScores = false;
      });
      return;
    }

    // Load profile details (username, creation date)
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (mounted && userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _username = data['username'] as String?;
          _createdAt = data['createdAt'] as Timestamp?;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile details: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }

    // Load high scores
    try {
      final scores = await _highScoreService.getUserHighScores();
      if (mounted) {
        setState(() {
          _userScores = scores;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading high scores: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingScores = false;
        });
      }
    }
  }

  // Method to show the change username dialog
  Future<void> _showChangeUsernameDialog() async {
    _usernameController.text = _username ?? ''; // Pre-fill with current username
    
    return showDialog<void>(
      context: context,
      barrierDismissible: !_isSavingUsername, // Prevent closing while saving
      builder: (BuildContext context) {
        // Use StatefulBuilder to manage dialog's state (like loading indicator)
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Username'),
              content: SingleChildScrollView(
                child: Form(
                  key: _usernameFormKey,
                  child: ListBody(
                    children: <Widget>[
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(hintText: "New username"),
                        autofocus: true,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a username';
                          }
                          final trimmedVal = val.trim();
                          if (trimmedVal.length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          if (trimmedVal.length > 15) {
                            return 'Username cannot exceed 15 characters';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmedVal)) {
                            return 'Only letters, numbers, and underscores allowed';
                          }
                          if (trimmedVal == _username) {
                            return 'Please enter a different username';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: _isSavingUsername ? null : () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  onPressed: _isSavingUsername ? null : () async {
                    await _updateUsername(setDialogState); // Pass setDialogState
                  },
                  child: _isSavingUsername 
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Method to update username in Firestore
  Future<void> _updateUsername(StateSetter setDialogState) async {
    if (_usernameFormKey.currentState!.validate()) {
      final newUsername = _usernameController.text.trim();
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      setDialogState(() { // Use setDialogState for dialog UI updates
        _isSavingUsername = true; 
      });

      try {
        // Check for uniqueness (case-insensitive)
        final querySnapshot = await _firestore
            .collection('users')
            .where('username_lowercase', isEqualTo: newUsername.toLowerCase())
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty && querySnapshot.docs.first.id != currentUser.uid) {
          // Username taken by someone else
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username already taken. Please choose another.'), backgroundColor: Colors.red),
          );
        } else {
          // Update Firestore using set with merge to handle missing documents
          await _firestore.collection('users').doc(currentUser.uid).set({
            'username': newUsername,
            'username_lowercase': newUsername.toLowerCase(),
            // Optionally add/update other fields like 'lastUpdated' if needed
            // 'lastUpdated': FieldValue.serverTimestamp(), 
          }, SetOptions(merge: true)); // Use merge: true

          // Update local state
          setState(() {
            _username = newUsername;
          });

          Navigator.of(context).pop(); // Close dialog on success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username updated successfully!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating username: $e'), backgroundColor: Colors.red),
        );
      } finally {
         setDialogState(() { // Use setDialogState for dialog UI updates
           _isSavingUsername = false;
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
    final currentUser = _authService.currentUser; // Get current user status

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE'),
        actions: [
          // Only show sign out if user is logged in
          if (_authService.currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
              tooltip: 'Sign Out',
            ),
        ],
      ),
      body: currentUser == null 
            // User is logged out - Show sign-in prompt (no change needed here)
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 80, color: Colors.grey[600]),
                      const SizedBox(height: 20),
                      Text(
                        'Sign in to view your profile and track high scores.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text('SIGN IN / REGISTER'),
                        onPressed: () {
                          // Navigate to the '/auth' route which requires authentication check
                          Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false); 
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // User is logged in - Show profile content
            : _isLoadingProfile // Check profile loading state
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, // Center content
                children: [
                  // User info card
                  Container(
                    // Use Card for better visual structure
                    child: Card(
                      elevation: 4,
                      color: Colors.purple[900]?.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.greenAccent, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.greenAccent,
                              child: Text(
                                // Use first letter of username or email
                                _username?.isNotEmpty == true 
                                  ? _username![0].toUpperCase() 
                                  : (currentUser?.email?.isNotEmpty == true ? currentUser!.email![0].toUpperCase() : 'P'),
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[900],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Username Display
                            Text(
                              _username ?? 'Player', // Display username or 'Player'
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Email Display
                            Text(
                              currentUser?.email ?? 'No email associated',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Member Since Display
                            if (_createdAt != null)
                              Text(
                                'Member Since: ${DateFormat.yMMMd().format(_createdAt!.toDate())}', // Format date
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white60,
                                ),
                              ),
                            
                            const SizedBox(height: 24),

                            // Change Username Button
                            ElevatedButton.icon(
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Change Username'),
                              onPressed: _showChangeUsernameDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent.withOpacity(0.8),
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                      letterSpacing: 1.1
                    ),
                  ),
                  const Divider(color: Colors.greenAccent, thickness: 1, height: 24),

                  _isLoadingScores // Check scores loading state
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: CircularProgressIndicator(),
                        )
                      : (_userScores == null || _userScores!.isEmpty)
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32.0),
                              child: Text(
                                'No scores yet. Play some games!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            )
                          : ListView( // Use ListView for scores
                              shrinkWrap: true, // Important inside SingleChildScrollView
                              physics: const NeverScrollableScrollPhysics(), // Disable ListView scrolling
                              children: _userScores!.entries.map((entry) {
                                return ListTile(
                                  leading: Icon(_getGameIcon(entry.key), color: Colors.purpleAccent), // Add game icon
                                  title: Text(
                                    entry.key.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  trailing: Text(
                                    '${entry.value}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                ],
              ),
            ),
    );
  }

  // Helper to get an icon based on game name
  IconData _getGameIcon(String gameName) {
    switch (gameName.toLowerCase()) {
      case 'snake':
        return Icons.turn_right; // Example icon
      case 'pacman':
        return Icons.adb; // Replaced Icons.ghost with a valid icon
      case 'pong':
        return Icons.sports_tennis; // Example icon
      default:
        return Icons.sports_esports;
    }
  }
}
