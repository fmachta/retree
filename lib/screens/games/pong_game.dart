import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class PongGame extends StatefulWidget {
  const PongGame({super.key});

  @override
  _PongGameState createState() => _PongGameState();
}

class _PongGameState extends State<PongGame> with TickerProviderStateMixin {
  // Game state
  Timer? _gameTimer;
  double paddleX = 0.0;
  double paddleWidth = 120.0;
  double paddleHeight = 20.0;
  double ballX = 0.0;
  double ballY = 0.0;
  double ballSize = 20.0;
  double ballDX = 4.0; // Ball horizontal speed
  double ballDY = 4.0; // Ball vertical speed
  int score = 0;
  int highScore = 0;
  int level = 1;
  int lives = 3;
  bool isGameStarted = false;
  bool isPaused = false;
  bool isGameOver = false;
  bool isInitialized = false;
  
  // Block properties
  List<Block> blocks = [];
  int blockRows = 5;
  int blockCols = 8;
  List<Color> blockColors = [
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.yellowAccent,
    Colors.greenAccent,
    Colors.blueAccent,
  ];
  
  // Screen dimensions
  double screenWidth = 0.0;
  double screenHeight = 0.0;
  
  // Animation controllers
  late AnimationController _ballPulseController;
  late Animation<double> _ballPulseAnimation;
  late AnimationController _paddleGlowController;
  late Animation<double> _paddleGlowAnimation;
  
  // For drag detection
  bool isDragging = false;
  double? dragStartX;
  
  @override
  void initState() {
    super.initState();
    
    // Set up ball pulse animation
    _ballPulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    
    _ballPulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _ballPulseController,
      curve: Curves.easeInOut,
    ));
    
    // Set up paddle glow animation
    _paddleGlowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _paddleGlowAnimation = Tween<double>(
      begin: 2.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _paddleGlowController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize game after the first frame to get screen size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      screenWidth = MediaQuery.of(context).size.width;
      screenHeight = MediaQuery.of(context).size.height - 
        kToolbarHeight - 
        MediaQuery.of(context).padding.top - 
        MediaQuery.of(context).padding.bottom - 
        120.0; // Allow space for controls
      _initializeGame();
      isInitialized = true;
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _ballPulseController.dispose();
    _paddleGlowController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    // Initialize paddle
    paddleX = screenWidth / 2 - paddleWidth / 2;
    
    // Reset ball position
    ballX = screenWidth / 2 - ballSize / 2;
    ballY = screenHeight / 2 - ballSize;
    
    // Randomize ball direction at start
    final random = Random();
    ballDX = (random.nextBool() ? 1 : -1) * (3.0 + random.nextDouble() * 2.0);
    ballDY = 4.0 + (level - 1) * 0.5; // Increase speed with level
    
    // Create blocks with level-dependent layout
    _createBlocks();
  }
  
  void _createBlocks() {
    blocks.clear();
    
    // Calculate block dimensions based on screen size
    double blockWidth = (screenWidth - 20) / blockCols;
    double blockHeight = screenHeight * 0.05;
    double blockSpacingX = 5.0;
    double blockSpacingY = 5.0;
    
    // Add more rows for higher levels (up to 7)
    int actualRows = min(blockRows + (level - 1), 7);
    
    for (int row = 0; row < actualRows; row++) {
      // Block health increases with row
      int health = 1;
      if (row < level && level > 2) {
        health = 2;
      }
      
      Color color = blockColors[row % blockColors.length];
      
      for (int col = 0; col < blockCols; col++) {
        double x = col * (blockWidth + blockSpacingX) + 10.0;
        double y = row * (blockHeight + blockSpacingY) + 50.0;
        
        blocks.add(Block(
          rect: Rect.fromLTWH(x, y, blockWidth, blockHeight),
          color: color,
          health: health,
        ));
      }
    }
  }
  
  void _startGame() {
    if (!isGameStarted) {
      setState(() {
        isGameStarted = true;
        isPaused = false;
        isGameOver = false;
        score = 0;
        level = 1;
        lives = 3;
      });
      
      _initializeGame();
      
      // Start game loop with a timer (~60 FPS)
      _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (!isPaused && isGameStarted && !isGameOver) {
          _update();
        }
      });
    }
  }
  
  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }
  
  void _resetBall() {
    ballX = screenWidth / 2 - ballSize / 2;
    ballY = screenHeight / 2 - ballSize / 2;
    
    // Randomize ball direction
    final random = Random();
    ballDX = (random.nextBool() ? 1 : -1) * (3.0 + random.nextDouble() * 2.0);
    ballDY = 4.0 + (level - 1) * 0.5;
  }
  
  void _goToNextLevel() {
    setState(() {
      level++;
      score += 50; // Bonus for clearing the level
      _resetBall();
      _createBlocks();
    });
  }

  void _update() {
    setState(() {
      // Update ball position
      ballX += ballDX;
      ballY += ballDY;

      // Wall collisions
      if (ballX <= 0 || ballX >= screenWidth - ballSize) {
        ballDX = -ballDX; // Bounce off left/right walls
        // Add slight random variance to angle on wall bounce
        ballDX *= 0.95 + (Random().nextDouble() * 0.1);
      }
      
      if (ballY <= 0) {
        ballDY = -ballDY; // Bounce off top wall
      }

      // Paddle collision
      Rect paddleRect = Rect.fromLTWH(paddleX, screenHeight - paddleHeight - 10, paddleWidth, paddleHeight);
      Rect ballRect = Rect.fromLTWH(ballX, ballY, ballSize, ballSize);
      
      if (paddleRect.overlaps(ballRect) && ballDY > 0) {
        // Calculate hit position relative to paddle center (range: -0.5 to 0.5)
        double hitPos = (ballX + ballSize / 2 - (paddleX + paddleWidth / 2)) / paddleWidth;
        
        // Bounce with angle based on hit position
        ballDY = -ballDY.abs(); // Always bounce upward
        ballDX = hitPos * 10.0; // Adjust horizontal speed based on hit point
        
        // Ensure minimum horizontal speed
        if (ballDX.abs() < 2.0) {
          ballDX = ballDX.sign * 2.0;
        }
        
        // Increment score
        score += 5;
      }

      // Block collisions
      for (int i = 0; i < blocks.length; i++) {
        if (blocks[i].rect.overlaps(ballRect)) {
          // Determine collision side
          final blockCenterX = blocks[i].rect.center.dx;
          final blockCenterY = blocks[i].rect.center.dy;
          final ballCenterX = ballX + ballSize / 2;
          final ballCenterY = ballY + ballSize / 2;
          
          final dx = blockCenterX - ballCenterX;
          final dy = blockCenterY - ballCenterY;
          
          // If horizontal distance is greater, it's a left/right collision
          if (dx.abs() * blocks[i].rect.height > dy.abs() * blocks[i].rect.width) {
            ballDX = -ballDX; // Horizontal bounce
          } else {
            ballDY = -ballDY; // Vertical bounce
          }
          
          // Reduce block health and remove if destroyed
          blocks[i].health--;
          if (blocks[i].health <= 0) {
            blocks.removeAt(i);
            score += 10;
          }
          
          break; // Only handle one collision per frame
        }
      }

      // Check for ball out of bounds (bottom)
      if (ballY >= screenHeight - ballSize) {
        lives--;
        
        if (lives <= 0) {
          // Game over
          _gameTimer?.cancel();
          isGameOver = true;
          
          // Update high score
          if (score > highScore) {
            highScore = score;
          }
        } else {
          // Reset ball for next life
          _resetBall();
        }
      }

      // Win condition - all blocks cleared
      if (blocks.isEmpty) {
        _goToNextLevel();
      }
    });
  }
  
  void _handlePaddleMove(double dx) {
    setState(() {
      paddleX += dx;
      
      // Keep paddle within screen bounds
      if (paddleX < 0) {
        paddleX = 0;
      } else if (paddleX > screenWidth - paddleWidth) {
        paddleX = screenWidth - paddleWidth;
      }
    });
  }
  
  void _handlePanStart(DragStartDetails details) {
    if (!isGameStarted || isPaused || isGameOver) return;
    dragStartX = details.globalPosition.dx;
    isDragging = true;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!isDragging || !isGameStarted || isPaused || isGameOver) return;
    
    double dx = details.globalPosition.dx - (dragStartX ?? 0);
    dragStartX = details.globalPosition.dx;
    _handlePaddleMove(dx);
  }

  void _handlePanEnd(DragEndDetails details) {
    isDragging = false;
    dragStartX = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'PONG BREAKOUT',
          style: TextStyle(
            fontFamily: 'joystix_monospace',
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: isGameStarted ? _togglePause : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (isGameStarted) {
                _gameTimer?.cancel();
              }
              _startGame();
            },
          ),
        ],
      ),
      body: isInitialized ? Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBox('SCORE', '$score'),
                _buildInfoBox('LEVEL', '$level'),
                _buildInfoBox('LIVES', '$lives'),
              ],
            ),
          ),
          
          // Game area
          Expanded(
            child: GestureDetector(
              onHorizontalDragStart: _handlePanStart,
              onHorizontalDragUpdate: _handlePanUpdate,
              onHorizontalDragEnd: _handlePanEnd,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                    color: Colors.blueAccent.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background grid
                    CustomPaint(
                      size: Size(screenWidth, screenHeight),
                      painter: GridPainter(),
                    ),
                    
                    // Draw blocks
                    ...blocks.map((block) => Positioned(
                      left: block.rect.left,
                      top: block.rect.top,
                      width: block.rect.width,
                      height: block.rect.height,
                      child: Container(
                        decoration: BoxDecoration(
                          color: block.color.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: block.color.withOpacity(0.5),
                              blurRadius: 3,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: block.health > 1 
                          ? Center(
                              child: Icon(
                                Icons.bolt,
                                color: Colors.white.withOpacity(0.7),
                                size: block.rect.height * 0.5,
                              ),
                            )
                          : null,
                      ),
                    )),
                    
                    // Ball with animation
                    if (isGameStarted && !isGameOver)
                      AnimatedBuilder(
                        animation: _ballPulseAnimation,
                        builder: (context, child) {
                          return Positioned(
                            left: ballX,
                            top: ballY,
                            child: Transform.scale(
                              scale: _ballPulseAnimation.value,
                              child: Container(
                                width: ballSize,
                                height: ballSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.8),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      ),
                    
                    // Paddle with glow animation
                    if (isGameStarted)
                      AnimatedBuilder(
                        animation: _paddleGlowAnimation,
                        builder: (context, child) {
                          return Positioned(
                            left: paddleX,
                            bottom: 10,
                            child: Container(
                              width: paddleWidth,
                              height: paddleHeight,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent,
                                    blurRadius: _paddleGlowAnimation.value,
                                    spreadRadius: _paddleGlowAnimation.value / 2,
                                  ),
                                ],
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.lightBlueAccent, Colors.blueAccent],
                                ),
                              ),
                            ),
                          );
                        }
                      ),
                    
                    // Start game overlay
                    if (!isGameStarted)
                      _buildStartGameOverlay(),
                    
                    // Game over overlay
                    if (isGameOver)
                      _buildGameOverOverlay(),
                    
                    // Pause overlay
                    if (isPaused && !isGameOver)
                      _buildPauseOverlay(),
                  ],
                ),
              ),
            ),
          ),
          
          // Controls
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  Icons.arrow_back,
                  () => _handlePaddleMove(-20),
                ),
                const SizedBox(width: 50),
                _buildControlButton(
                  Icons.arrow_forward,
                  () => _handlePaddleMove(20),
                ),
              ],
            ),
          ),
        ],
      ) : const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  Widget _buildInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.blueAccent, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontFamily: 'joystix_monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 16,
              fontFamily: 'joystix_monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: Colors.blueAccent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: Colors.blueAccent,
            size: 30,
          ),
        ),
      ),
    );
  }
  
  Widget _buildStartGameOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Icon(
              Icons.sports_volleyball,
              size: 60,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 20),
            const Text(
              'PONG BREAKOUT',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 24,
                fontFamily: 'joystix_monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'START',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'joystix_monospace',
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Swipe or use arrows\nto move the paddle',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontFamily: 'joystix_monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 28,
                fontFamily: 'joystix_monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SCORE: $score',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'joystix_monospace',
              ),
            ),
            const SizedBox(height: 10),
            if (score >= highScore && score > 0)
              const Text(
                'NEW HIGH SCORE!',
                style: TextStyle(
                  color: Colors.yellowAccent,
                  fontSize: 16,
                  fontFamily: 'joystix_monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'PLAY AGAIN',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'joystix_monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontFamily: 'joystix_monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _togglePause,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'RESUME',
                    style: TextStyle(
                      fontFamily: 'joystix_monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'RESTART',
                    style: TextStyle(
                      fontFamily: 'joystix_monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Block {
  final Rect rect;
  final Color color;
  int health;
  
  Block({
    required this.rect,
    required this.color,
    this.health = 1,
  });
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..strokeWidth = 0.5;
    
    // Draw horizontal lines
    for (int i = 0; i <= 10; i++) {
      final y = size.height * (i / 10);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw vertical lines
    for (int i = 0; i <= 10; i++) {
      final x = size.width * (i / 10);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}