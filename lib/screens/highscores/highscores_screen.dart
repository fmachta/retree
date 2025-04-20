import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added missing import
import '../../services/highscore_service.dart';
import '../../services/auth_service.dart';

class HighScoresScreen extends StatefulWidget {
  final String? gameType;
  final bool firebaseInitialized;
  
  const HighScoresScreen({
    Key? key, 
    this.gameType,
    this.firebaseInitialized = true,
  }) : super(key: key);

  @override
  _HighScoresScreenState createState() => _HighScoresScreenState();
}

class _HighScoresScreenState extends State<HighScoresScreen> with SingleTickerProviderStateMixin {
  final HighScoreService _highScoreService = HighScoreService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  List<String> _games = ['Snake', 'Pacman', 'Pong'];
  String _selectedGame = 'Snake';
  bool _isLoading = true;
  List<Map<String, dynamic>> _leaderboardData = [];
  Map<String, dynamic>? _userScores;
  String? _currentUserUsername; // To store the logged-in user's username

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _games.length, vsync: this);
    
    if (widget.gameType != null) {
      _selectedGame = widget.gameType!;
      int index = _games.indexOf(_selectedGame);
      if (index != -1) {
        _tabController.index = index;
      }
    }
    
    _loadScores();
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedGame = _games[_tabController.index];
          _isLoading = true;
        });
        _loadScores();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check for arguments from named routes
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is String && arguments != _selectedGame) {
      final gameType = arguments;
      final index = _games.indexOf(gameType);
      if (index != -1 && _tabController.index != index) {
        _selectedGame = gameType;
        _tabController.animateTo(index);
        _loadScores();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadScores() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Check if Firebase is initialized and service is available
      if (!widget.firebaseInitialized || !_highScoreService.isAvailable) {
        if (mounted) {
          setState(() {
            _leaderboardData = [];
            _userScores = null;
            _isLoading = false;
          });
        }
        return;
      }

      // Get global leaderboard
      final leaderboard = await _highScoreService.getGameLeaderboard(_selectedGame);
      
      // Get user scores and username if logged in
      Map<String, dynamic>? userScores;
      String? currentUsername;
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        try {
          // Fetch user scores
          userScores = await _highScoreService.getUserHighScores();
          
          // Fetch username from Firestore
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          if (userDoc.exists) {
            currentUsername = userDoc.data()?['username'] as String?;
          }
        } catch (e) {
          // Silently handle errors
          print('Error fetching user data: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _leaderboardData = leaderboard;
          _userScores = userScores;
          _currentUserUsername = currentUsername; // Store the username
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading scores: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HIGH SCORES'),
        actions: [
          // Removed conditional sign-in button
          // Always show profile button if user is logged in
          if (_authService.currentUser != null) 
            IconButton(
              icon: const Icon(Icons.person, color: Colors.greenAccent),
              tooltip: 'Profile',
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _games.map((game) => Tab(text: game.toUpperCase())).toList(),
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _games.map((game) {
          return _buildLeaderboardTab(game);
        }).toList(),
      ),
    );
  }

  Widget _buildLeaderboardTab(String game) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show message if Firebase is not available
    if (!widget.firebaseInitialized || !_highScoreService.isAvailable) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Online scores unavailable',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can still play games and track local scores',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadScores,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // Get user's score for this game if available
    int? userScore;
    if (_userScores != null && _userScores!.containsKey(game)) {
      userScore = _userScores![game] as int?;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // User's score card - Enhanced
          if (userScore != null)
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20),
              color: Colors.purple[900]?.withOpacity(0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.greenAccent, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.yellowAccent, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'YOUR BEST:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(), // Pushes score to the right
                    Text(
                      userScore.toString(),
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Leaderboard title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.greenAccent, width: 2)),
            ),
            child: Row(
              children: const [
                SizedBox(width: 50, child: Text('RANK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))), // Adjusted width
                SizedBox(width: 16),
                Expanded(child: Text('PLAYER', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
                SizedBox(width: 80, child: Text('SCORE', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
              ],
            ),
          ),
          
          // Leaderboard list
          Expanded(
            child: _leaderboardData.isEmpty
                ? const Center(child: Text('No scores yet. Be the first!'))
                : ListView.builder(
                    itemCount: _leaderboardData.length,
                    itemBuilder: (context, index) {
                      final scoreData = _leaderboardData[index];
                      final rank = index + 1;
                      // Use fetched username for comparison
                      final bool isCurrentUser = _currentUserUsername != null && 
                                                 scoreData['username'] == _currentUserUsername; 

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), // Added horizontal padding
                        margin: const EdgeInsets.symmetric(vertical: 2), // Added vertical margin
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey[850]!)),
                          color: isCurrentUser ? Colors.purple.withOpacity(0.3) : Colors.black.withOpacity(0.2), // Enhanced highlight
                          borderRadius: BorderRadius.circular(4), // Rounded corners
                        ),
                        child: Row(
                          children: [
                            // Rank Widget (Icon or Text)
                            SizedBox(
                              width: 50, // Adjusted width
                              child: _buildRankWidget(rank), // Use helper widget
                            ),
                            const SizedBox(width: 16),
                            // Optional: Icon for current user
                            if (isCurrentUser) 
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Icon(Icons.person, size: 16, color: Colors.greenAccent.withOpacity(0.8)),
                              ),
                            Expanded(
                              child: Text(
                                scoreData['username'] ?? 'Unknown Player',
                                style: TextStyle(
                                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                  color: isCurrentUser ? Colors.greenAccent : Colors.white, // Brighter color for current user
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis, // Prevent long names from overflowing
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(
                                '${scoreData['score']}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrentUser ? Colors.greenAccent : (rank <= 3 ? Colors.yellowAccent.withOpacity(0.9) : Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Helper widget to display rank with icons for top 3
  Widget _buildRankWidget(int rank) {
    Widget rankDisplay;
    Color? iconColor;
    IconData? iconData;

    switch (rank) {
      case 1:
        iconData = Icons.emoji_events;
        iconColor = Colors.amberAccent; // Gold
        break;
      case 2:
        iconData = Icons.emoji_events;
        iconColor = Colors.grey[400]; // Silver
        break;
      case 3:
        iconData = Icons.emoji_events;
        iconColor = Colors.brown[300]; // Bronze
        break;
      // No default needed if rankDisplay is initialized before switch
    }

    // Initialize rankDisplay before the switch or handle default case properly
    if (iconData != null) {
      rankDisplay = Icon(iconData, color: iconColor, size: 22);
    } else {
      // Default case: display rank number
      rankDisplay = Text(
        '$rank',
        textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white70,
          ),
        );
    }
    // Removed redundant assignment block

    return Center(child: rankDisplay);
  }
}
