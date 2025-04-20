import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Game Element Models
class Player {
  Rect rect;
  Player({required this.rect});
}

class Alien {
  Rect rect;
  bool alive = true;
  Alien({required this.rect});
}

class Bullet {
  Rect rect;
  bool isPlayerBullet; // true for player, false for alien
  Bullet({required this.rect, required this.isPlayerBullet});
}

// +++ Custom Painter moved to top level +++
class _SpaceInvadersPainter extends CustomPainter {
  final Player? player; // Player can be null during setup
  final List<Alien> aliens;
  final List<Bullet> bullets;

  _SpaceInvadersPainter({
    required this.player, // Keep required, but handle null in paint
    required this.aliens,
    required this.bullets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final playerPaint = Paint()..color = Colors.greenAccent;
    final alienPaint = Paint()..color = Colors.purpleAccent;
    final playerBulletPaint = Paint()..color = Colors.lightGreenAccent;
    final alienBulletPaint = Paint()..color = Colors.deepOrangeAccent;

    // Draw Player (only if not null)
    if (player != null) {
      canvas.drawRect(player!.rect, playerPaint);
    }

    // Draw Aliens
    for (final alien in aliens) {
      if (alien.alive) {
        // Simple rectangle for now, could use images later
        canvas.drawRect(alien.rect, alienPaint);
      }
    }

    // Draw Bullets
    for (final bullet in bullets) {
      canvas.drawRect(bullet.rect, bullet.isPlayerBullet ? playerBulletPaint : alienBulletPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint every frame
  }
}
// ++++++++++++++++++++++++++++++++++++++++

class SpaceInvadersGame extends StatefulWidget {
  const SpaceInvadersGame({super.key});

  @override
  State<SpaceInvadersGame> createState() => _SpaceInvadersGameState();
}

class _SpaceInvadersGameState extends State<SpaceInvadersGame> with TickerProviderStateMixin {
  late AnimationController _controller;
  Player? _player; // Make player nullable for setup phase
  List<Alien> _aliens = [];
  List<Bullet> _bullets = [];
  int _score = 0;
  bool _gameOver = false;
  bool _gameStarted = false;
  int _lives = 3;
  int _wave = 1; // Start at wave 1
  bool _gameSetupComplete = false; // New flag for reliable setup

  // Game Configuration
  final double _playerWidth = 40.0;
  final double _playerHeight = 20.0;
  final double _playerSpeed = 5.0;
  final double _alienWidth = 30.0;
  final double _alienHeight = 20.0;
  final double _alienSpacing = 15.0;
  final int _aliensPerRow = 8;
  final int _numAlienRows = 4;
  double _alienSpeed = 1.0; // Initial speed
  double _alienDirection = 1.0; // 1 for right, -1 for left
  double _alienVerticalDrop = 10.0;
  final double _bulletWidth = 4.0;
  final double _bulletHeight = 10.0;
  final double _playerBulletSpeed = 8.0;
  final double _alienBulletSpeed = 4.0;
  final double _alienShootChance = 0.005; // Chance per alien per frame

  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60 FPS
    )..addListener(_updateGame);

    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) { // Ensure widget is mounted before requesting focus
         FocusScope.of(context).requestFocus(_focusNode);
         // Don't initialize game here anymore, wait for LayoutBuilder
       }
    });
  }

  // Setup game elements based on screen size
  void _setupGame(Size size) {
     _player = Player(
       rect: Rect.fromLTWH(
         (size.width - _playerWidth) / 2,
         size.height - _playerHeight - 100, // Increased offset to move player higher
         _playerWidth,
         _playerHeight,
       ),
     );
     _createAliens(size); // Create aliens based on the provided size
     _bullets.clear();
     _score = 0;
     _lives = 3;
     _wave = 1;
     _alienSpeed = 1.0 + (_wave - 1) * 0.2; // Increase speed slightly per wave
     _alienDirection = 1.0;
     _gameOver = false;
     _gameStarted = false;
     if (_controller.isAnimating) {
       _controller.stop();
     }
     // Set the setup complete flag after elements are created
     _gameSetupComplete = true;
  }

  // Reset game state (e.g., after game over)
  void _resetGame() {
    final size = MediaQuery.of(context).size; // Still need size here for reset
    if (size.isEmpty) return; // Avoid reset if size isn't available yet

    setState(() {
      _setupGame(size); // Re-setup the game elements
      // Reset score, lives, wave etc.
      _score = 0;
      _lives = 3;
      _wave = 1;
    });
  }

  void _createAliens(Size size) {
    _aliens.clear();
    final double totalAlienBlockWidth = (_alienWidth + _alienSpacing) * _aliensPerRow - _alienSpacing;
    final double startX = (size.width - totalAlienBlockWidth) / 2;
    double currentY = 60.0; // Starting Y position

    for (int row = 0; row < _numAlienRows; row++) {
      double currentX = startX;
      for (int col = 0; col < _aliensPerRow; col++) {
        _aliens.add(Alien(rect: Rect.fromLTWH(currentX, currentY, _alienWidth, _alienHeight)));
        currentX += _alienWidth + _alienSpacing;
      }
      currentY += _alienHeight + _alienSpacing;
    }
     _alienSpeed = 1.0 + (_wave -1) * 0.2; // Reset speed for new wave
     _alienDirection = 1.0; // Reset direction
  }

  void _startGame() {
    if (!_gameStarted && !_gameOver) {
      _gameStarted = true;
      _controller.repeat();
    } else if (_gameOver) {
      _resetGame(); // Use the new reset method
      setState(() {
         _gameStarted = true; // Mark as started after reset
      });
      _controller.repeat();
    }
  }

  void _updateGame() {
    if (!_gameStarted || _gameOver) return;

    final size = MediaQuery.of(context).size;
    bool wallHit = false;
    double minAlienX = double.infinity;
    double maxAlienX = double.negativeInfinity;

    // --- Alien Movement ---
    for (final alien in _aliens) {
      if (!alien.alive) continue;
      alien.rect = alien.rect.translate(_alienSpeed * _alienDirection, 0);
      minAlienX = min(minAlienX, alien.rect.left);
      maxAlienX = max(maxAlienX, alien.rect.right);
      if (alien.rect.left <= 0 || alien.rect.right >= size.width) {
        wallHit = true;
      }
       // Check if aliens reached player level (add null check for _player)
      if (_player != null && alien.rect.bottom >= _player!.rect.top) {
         _triggerGameOver("Aliens reached the bottom!");
         return; // Stop further updates this frame
      }
    }

    // If wall hit, reverse direction and move down
    if (wallHit) {
      _alienDirection *= -1;
      _alienSpeed += 0.1; // Increase speed slightly on wall hit
      for (final alien in _aliens) {
         if (!alien.alive) continue;
        alien.rect = alien.rect.translate(0, _alienVerticalDrop);
      }
    }

    // --- Bullet Movement & Collision ---
    List<Bullet> bulletsToRemove = [];
    List<Alien> aliensToRemove = []; // Track aliens hit in this frame

    for (final bullet in _bullets) {
      // Move bullet
      bullet.rect = bullet.rect.translate(
          0, bullet.isPlayerBullet ? -_playerBulletSpeed : _alienBulletSpeed);

      // Check for out of bounds
      if (bullet.rect.bottom < 0 || bullet.rect.top > size.height) {
        bulletsToRemove.add(bullet);
        continue;
      }

      // Check collision with player (for alien bullets) (add null check for _player)
      if (!bullet.isPlayerBullet && _player != null && bullet.rect.overlaps(_player!.rect)) {
        bulletsToRemove.add(bullet);
        _handlePlayerHit();
        if (_gameOver) return; // Stop if game over
        continue;
      }

      // Check collision with aliens (for player bullets)
      if (bullet.isPlayerBullet) {
        for (final alien in _aliens) {
          if (alien.alive && bullet.rect.overlaps(alien.rect)) {
            bulletsToRemove.add(bullet);
            alien.alive = false; // Mark alien as hit
            aliensToRemove.add(alien); // Add to removal list for score
            _score += 10; // Increase score
            break; // Bullet hits only one alien
          }
        }
      }
    }

    // Remove bullets and aliens that were hit
    _bullets.removeWhere((b) => bulletsToRemove.contains(b));
    // Note: We don't remove aliens from the list immediately to allow others to shoot,
    // but they are marked as `alive = false`. We check this flag everywhere.

    // --- Alien Shooting ---
    for (final alien in _aliens) {
       if (!alien.alive) continue;
       // Only allow aliens at the bottom of their column to shoot (optional complexity)
       // bool canShoot = true;
       // for (final otherAlien in _aliens) {
       //    if (otherAlien.alive && otherAlien.rect.left == alien.rect.left && otherAlien.rect.top > alien.rect.top) {
       //       canShoot = false;
       //       break;
       //    }
       // }

       // if (canShoot && Random().nextDouble() < _alienShootChance) {
       if (Random().nextDouble() < _alienShootChance + (_wave * 0.0005)) { // Slightly increase shoot chance per wave
         _bullets.add(Bullet(
           rect: Rect.fromCenter(
             center: alien.rect.bottomCenter,
             width: _bulletWidth,
             height: _bulletHeight,
           ),
           isPlayerBullet: false,
         ));
       }
    }

    // --- Check for Wave Completion ---
    if (_aliens.every((a) => !a.alive)) {
       _wave++;
       _bullets.clear(); // Clear bullets between waves
       _createAliens(size); // Create next wave
       // Optionally show a "Wave X" message
    }


    // Update UI
    if (mounted) {
      setState(() {});
    }
  }

  void _handlePlayerHit() {
     _lives--;
     if (_lives <= 0) {
       _triggerGameOver("Out of lives!");
     } else {
       // Optional: Add brief invincibility or visual feedback
       if (mounted) setState(() {}); // Update life display
     }
  }

  void _triggerGameOver(String reason) {
     _gameOver = true;
     _gameStarted = false;
     _controller.stop();
     // Optional: Show game over message with the reason
     if (mounted) setState(() {});
  }


  void _movePlayer(double dx) {
    if (!_gameStarted || _gameOver || _player == null) return; // Add null check
    final size = MediaQuery.of(context).size;
    setState(() {
      // Calculate the new left position
      double newLeft = _player!.rect.left + dx;
      // Clamp the new left position to stay within screen bounds
      newLeft = newLeft.clamp(0.0, size.width - _player!.rect.width);
      // Create the new Rect with the clamped position
      _player!.rect = Rect.fromLTWH(newLeft, _player!.rect.top, _player!.rect.width, _player!.rect.height);
    });
  }

  void _playerShoot() {
    if (!_gameStarted || _gameOver || _player == null) return; // Add null check
    // Limit number of player bullets on screen? (Optional)
    // int playerBulletsOnScreen = _bullets.where((b) => b.isPlayerBullet).length;
    // if (playerBulletsOnScreen < 3) {
       setState(() {
         _bullets.add(Bullet(
           rect: Rect.fromCenter(
             center: _player!.rect.topCenter, // Use null-aware access
             width: _bulletWidth,
             height: _bulletHeight,
           ),
           isPlayerBullet: true,
         ));
       });
    // }
  }


  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest; // Get reliable size from LayoutBuilder

      // Setup game only once when layout is known and setup isn't complete
      if (!_gameSetupComplete && size.width > 0 && size.height > 0) {
        // Use WidgetsBinding.instance.addPostFrameCallback to avoid calling setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) { // Check if mounted before calling setState
             setState(() {
               _setupGame(size);
             });
          }
        });
      }

      // Show loading indicator until game setup is complete
      if (!_gameSetupComplete) {
        return Scaffold(
          appBar: AppBar(title: const Text('Space Invaders')),
          backgroundColor: Colors.black,
          body: const Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
        );
      }

      // --- Game UI build starts here ---
      return Scaffold(
        appBar: AppBar(
          title: const Text('Space Invaders'),
          actions: [
             Padding( // Keep padding
               padding: const EdgeInsets.symmetric(horizontal: 4.0),
               // Removed Flexible wrapper
               child: Text('Wave: $_wave', style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
             ),
             Padding( // Keep Lives padding
               padding: const EdgeInsets.symmetric(horizontal: 4.0),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: List.generate(_lives, (index) => Icon(Icons.favorite, color: Colors.red, size: 20)),
               ),
             ),
             Padding( // Keep padding
               padding: const EdgeInsets.only(right: 8.0),
               // Removed Flexible wrapper
               child: Text('Score: $_score', style: const TextStyle(fontSize: 18), overflow: TextOverflow.ellipsis, textAlign: TextAlign.right), // Align right within padding
             ),
          ],
        ),
        backgroundColor: Colors.black,
        body: RawKeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _movePlayer(-_playerSpeed);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _movePlayer(_playerSpeed);
            } else if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.arrowUp) {
               if (_gameStarted && !_gameOver) {
                  _playerShoot();
               } else {
                  _startGame(); // Start game if not started or game over
               }
            } else if (event.logicalKey == LogicalKeyboardKey.enter) {
               if (!_gameStarted || _gameOver) {
                 _startGame();
               }
            }
          }
        },
        child: GestureDetector(
           onTap: () { // Tap to start or shoot
              if (!_gameStarted || _gameOver) {
                 _startGame();
              } else {
                 _playerShoot();
              }
           },
           onHorizontalDragUpdate: (details) { // Drag to move player
              if (_gameStarted && !_gameOver) {
                 _movePlayer(details.delta.dx);
              }
           },
          child: Stack(
            children: [
              // Game Area Painter
              Positioned.fill(
                child: CustomPaint(
                  painter: _SpaceInvadersPainter(
                    player: _player,
                    aliens: _aliens,
                    bullets: _bullets,
                  ),
                ),
              ),
              // Game Over / Start Message Overlay
              if (_gameOver || !_gameStarted)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent, width: 2)
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _gameOver ? 'GAME OVER!' : 'SPACE INVADERS',
                          style: const TextStyle(fontSize: 28, color: Colors.redAccent, fontWeight: FontWeight.bold, fontFamily: 'joystix_monospace'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                         if (_gameOver)
                           Text(
                             'Final Score: $_score (Wave: $_wave)',
                             style: const TextStyle(fontSize: 20, color: Colors.white, fontFamily: 'joystix_monospace'),
                           ),
                        const SizedBox(height: 25),
                        Text(
                           _gameOver ? 'Press Space/Enter or Tap to Play Again' : 'Press Space/Enter or Tap to Start',
                           style: const TextStyle(fontSize: 16, color: Colors.white70, fontFamily: 'joystix_monospace'),
                           textAlign: TextAlign.center,
                        ),
                         const SizedBox(height: 15),
                         const Text(
                           'Use Left/Right Arrows or Drag to Move\nSpace/Up Arrow or Tap to Shoot',
                           style: TextStyle(fontSize: 14, color: Colors.white54, fontFamily: 'joystix_monospace'),
                           textAlign: TextAlign.center,
                         ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }); // <-- Add missing closing parenthesis and semicolon for LayoutBuilder
} // build method ends

} // <-- Add missing closing brace for _SpaceInvadersGameState class
