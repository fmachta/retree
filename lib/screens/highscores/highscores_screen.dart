import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      
      // Get user scores if logged in
      Map<String, dynamic>? userScores;
      if (_authService.currentUser != null) {
        try {
          userScores = await _highScoreService.getUserHighScores();
        } catch (e) {
          // Silently handle errors, as user might not be logged in
          print('Error fetching user scores: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _leaderboardData = leaderboard;
          _userScores = userScores;
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
          if (_authService.currentUser == null)
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/auth');
              },
              icon: const Icon(Icons.login, color: Colors.greenAccent, size: 16),
              label: const Text(
                'SIGN IN',
                style: TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
            )
          else
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
          // User's score card
          if (userScore != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'YOUR BEST SCORE:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userScore.toString(),
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
                SizedBox(width: 40, child: Text('RANK', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 16),
                Expanded(child: Text('PLAYER', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 80, child: Text('SCORE', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
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
                      final score = _leaderboardData[index];
                      final isCurrentUser = _authService.currentUser != null && 
                                           score['username'] == (_authService.currentUser!.email ?? 'Anonymous Player');
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
                          color: isCurrentUser ? Colors.purple.withOpacity(0.2) : null,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: index < 3 ? Colors.greenAccent : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                score['username'] ?? 'Unknown Player',
                                style: TextStyle(
                                  fontWeight: isCurrentUser ? FontWeight.bold : null,
                                  color: isCurrentUser ? Colors.greenAccent : null,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(
                                '${score['score']}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: index < 3 ? Colors.greenAccent : null,
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
} 