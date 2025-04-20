import 'package:flutter/material.dart';
import 'animated_background.dart';
import '../games/snake_game.dart'; 
import '../games/pong_game.dart';
import '../games/tetris_game.dart';
import '../games/pacman_game.dart';
import '../games/breakout_game.dart'; // Import the actual game
import '../games/space_invaders_game.dart'; // Import the actual game
// Will create these files later

class GameSelectionScreen extends StatefulWidget {
  const GameSelectionScreen({super.key});

  @override
  _GameSelectionScreenState createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen> {
  final List<Map<String, dynamic>> games = [
    {
      'name': 'Snake',
      'description': 'Eat apples, grow longer, avoid walls and yourself!',
      'image': 'assets/snake_icon.png',
      'screen': const SnakeGame(),
      'color': Colors.greenAccent,
      'icon': Icons.play_arrow_rounded,
    },
    {
      'name': 'Pong',
      'description': 'Classic table tennis simulation game',
      'image': 'assets/pong_icon.png',
      'screen': const PongGame(),
      'color': Colors.blueAccent,
      'icon': Icons.sports_tennis,
    },
    {
      'name': 'Tetris',
      'description': 'Arrange falling blocks to clear complete lines',
      'image': 'assets/tetris_icon.png',
      'screen': const TetrisGame(),
      'color': Colors.redAccent,
      'icon': Icons.grid_view,
    },
    {
      'name': 'Pacman',
      'description': 'Eat dots while avoiding ghosts in the maze',
      'image': 'assets/pacman_icon.png',
      'screen': const PacmanGame(),
      'color': Colors.yellowAccent,
      'icon': Icons.brightness_1_rounded,
    },
    {
      'name': 'Space Invaders',
      'description': 'Shoot down waves of descending alien invaders',
      'image': 'assets/space_invaders_icon.png', // You might need to add this asset
      'screen': const SpaceInvadersGame(), // Use the actual game screen
      'color': Colors.purpleAccent,
      'icon': Icons.bug_report,
    },
    {
      'name': 'Breakout',
      'description': 'Break all bricks with a bouncing ball',
      'image': 'assets/breakout_icon.png', // You might need to add this asset
      'screen': const BreakoutGame(), // Use the actual game screen
      'color': Colors.orangeAccent,
      'icon': Icons.extension,
    },
  ];

  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'SELECT A GAME',
          style: TextStyle(
            fontFamily: 'joystix_monospace',
            fontSize: 22,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Arcade Classics',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      fontFamily: 'joystix_monospace',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.65, // Increased height for cards to accommodate content
                      ),
                      padding: const EdgeInsets.all(8),
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        return MouseRegion(
                          onEnter: (_) => setState(() => _hoveredIndex = index),
                          onExit: (_) => setState(() => _hoveredIndex = null),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform: _hoveredIndex == index 
                                ? (Matrix4.identity()..scale(1.05))
                                : Matrix4.identity(),
                            child: _buildGameCard(game, index),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game, int index) {
    bool isHovered = _hoveredIndex == index;
    
    return Card(
      elevation: isHovered ? 8 : 4,
      color: Colors.black.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: game['color'],
          width: isHovered ? 2.5 : 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => game['screen'],
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: game['color'].withOpacity(0.3),
        highlightColor: game['color'].withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use minimum space needed
            children: [
              // Game icon with glow effect
              Container(
                width: 60, // Reduced size
                height: 60, // Reduced size
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: game['color'].withOpacity(0.6),
                      blurRadius: isHovered ? 15 : 8,
                      spreadRadius: isHovered ? 2 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  game['icon'],
                  color: game['color'],
                  size: 30, // Reduced size
                ),
              ),
              const SizedBox(height: 8), // Reduced spacing
              // Game title
              Text(
                game['name'].toUpperCase(),
                style: TextStyle(
                  fontSize: 14, // Reduced font size
                  fontFamily: 'joystix_monospace',
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6), // Reduced spacing
              // Game description
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    game['description'],
                    style: TextStyle(
                      fontSize: 10, // Smaller font
                      color: Colors.white70,
                      fontFamily: 'joystix_monospace',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3, // Allow up to 3 lines
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Play button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => game['screen'],
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 500),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: game['color'],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Reduced padding
                  minimumSize: Size(100, 30), // Reduced button size
                  side: BorderSide(color: game['color'], width: 1.0),
                ),
                child: Text(
                  'PLAY',
                  style: TextStyle(
                    fontFamily: 'joystix_monospace',
                    fontSize: 12, // Smaller font
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder for games that will be implemented later
class ComingSoonScreen extends StatelessWidget {
  final String gameName;
  final Color color;

  const ComingSoonScreen({Key? key, required this.gameName, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$gameName'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: color,
            ),
            const SizedBox(height: 24),
            Text(
              '$gameName Coming Soon!',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'joystix_monospace',
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This game is currently under development.',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'joystix_monospace',
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                side: BorderSide(color: color, width: 2),
              ),
              child: Text(
                'BACK TO GAMES',
                style: TextStyle(
                  fontFamily: 'joystix_monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
