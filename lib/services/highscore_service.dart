import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HighScoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAvailable = true;

  HighScoreService() {
    // Check if Firebase services are available
    try {
      _firestore.collection('test').snapshots();
      _isAvailable = true;
    } catch (e) {
      print('Firestore not available: $e');
      _isAvailable = false;
    }
  }

  // Check if the service is available
  bool get isAvailable => _isAvailable;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _globalScoresCollection => _firestore.collection('globalScores');

  // Get user document reference
  DocumentReference get userDocument {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _usersCollection.doc(user.uid);
  }

  // Save a user's high score for a specific game
  Future<void> saveUserHighScore(String game, int score, {String? username}) async {
    if (!_isAvailable) {
      print('HighScoreService is not available');
      return;
    }
    
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update user's document with game scores
      await userDocument.set({
        'lastUpdated': FieldValue.serverTimestamp(),
        'username': username ?? user.email ?? 'Anonymous Player',
        'scores': {
          game: score,
        }
      }, SetOptions(merge: true));

      // Also add to global leaderboard
      await _globalScoresCollection.doc().set({
        'userId': user.uid,
        'username': username ?? user.email ?? 'Anonymous Player',
        'game': game,
        'score': score,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving high score: $e');
    }
  }

  // Get user's high scores for all games
  Future<Map<String, dynamic>?> getUserHighScores() async {
    if (!_isAvailable) {
      print('HighScoreService is not available');
      return null;
    }
    
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final doc = await userDocument.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['scores'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting user high scores: $e');
      return null;
    }
  }

  // Get user's high score for a specific game
  Future<int?> getUserGameHighScore(String game) async {
    if (!_isAvailable) {
      print('HighScoreService is not available');
      return null;
    }
    
    try {
      final scores = await getUserHighScores();
      if (scores != null && scores.containsKey(game)) {
        return scores[game] as int?;
      }
      return null;
    } catch (e) {
      print('Error getting game high score: $e');
      return null;
    }
  }

  // Get global leaderboard for a specific game
  Future<List<Map<String, dynamic>>> getGameLeaderboard(String game, {int limit = 10}) async {
    if (!_isAvailable) {
      print('HighScoreService is not available');
      return [];
    }
    
    try {
      final querySnapshot = await _globalScoresCollection
          .where('game', isEqualTo: game)
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'username': doc['username'],
                'score': doc['score'],
                'timestamp': doc['timestamp'],
              })
          .toList();
    } catch (e) {
      print('Error getting game leaderboard: $e');
      return [];
    }
  }
} 