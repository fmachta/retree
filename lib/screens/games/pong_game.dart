import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:provider/provider.dart'; // Added for accessing services
import '../../services/auth_service.dart'; // Added for user ID
import '../../services/highscore_service.dart'; // Added for saving scores

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
  final HighScoreService _highscoreService = HighScoreService(); // Corrected class name capitalization
  String? _userId; // Added for storing user ID

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

    // Get user ID using the correct property
    // Use context.read for one-time read in initState
    _userId = context.read<AuthService>().currentUser?.uid; 

    // Defer initialization until after first frame layout
    // No need for WidgetsBinding here if using LayoutBuilder in build
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _ballPulseController.dispose();
    _paddleGlowController.dispose();
    super.dispose();
  }

  // Initialize game elements based on screen size
  void _initializeGame() {
    // Ensure screen dimensions are valid before initializing
    if (screenWidth <= 0 || screenHeight <= 0) return; 

    paddleX = screenWidth / 2 - paddleWidth / 2;
    ballX = screenWidth / 2 - ballSize / 2;
    ballY = screenHeight / 2 - ballSize; // Start ball higher up
    
    final random = Random();
    ballDX = (random.nextBool() ? 1 : -1) * (3.0 + random.nextDouble() * 2.0);
    ballDY = min(4.0 + (level - 1) * 0.5, 10.0); // Cap vertical speed

    _createBlocks();
  }
  
  // Create blocks based on level
  void _createBlocks() {
     if (screenWidth <= 0 || screenHeight <= 0) return; // Need dimensions

    blocks.clear();
    double blockWidth = (screenWidth - 20) / blockCols; // Adjusted for padding
    double blockHeight = screenHeight * 0.04; // Slightly smaller blocks
    double blockSpacingX = 4.0; // Reduced spacing
    double blockSpacingY = 4.0;
    double topOffset = screenHeight * 0.1; // Start blocks lower down

    int actualRows = min(blockRows + (level - 1), 7);
    
    for (int row = 0; row < actualRows; row++) {
      int health = 1 + (row ~/ 2); // Health increases every 2 rows
      if (level > 3) health++; // Increase base health on later levels
      
      Color color = blockColors[row % blockColors.length];
      
      for (int col = 0; col < blockCols; col++) {
        double x = col * (blockWidth + blockSpacingX) + 10.0; // Start with padding
        double y = row * (blockHeight + blockSpacingY) + topOffset;
        
        blocks.add(Block(
          rect: Rect.fromLTWH(x, y, blockWidth, blockHeight),
          color: color,
          health: health,
        ));
      }
    }
  }
  
  // Start or restart the game
  void _startGame() {
    if (!isInitialized) return; 

    setState(() {
      isGameStarted = true;
      isPaused = false;
      isGameOver = false;
      score = 0;
      level = 1;
      lives = 3;
      highScore = highScore; // Keep existing high score display
      _initializeGame(); 
    });

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!isPaused && isGameStarted && !isGameOver) {
        _update();
      }
    });
  }
  
  // Toggle pause state
  void _togglePause() {
    if (!isGameStarted || isGameOver) return; 
    setState(() {
      isPaused = !isPaused;
    });
  }
  
  // Reset ball position and speed after losing a life
  void _resetBall() {
    if (screenWidth <= 0 || screenHeight <= 0) return;

    ballX = screenWidth / 2 - ballSize / 2;
    ballY = screenHeight * 0.6; // Reset lower down
    
    final random = Random();
    ballDX = (random.nextBool() ? 1 : -1) * (3.0 + random.nextDouble() * 2.0);
    ballDY = min(4.0 + (level - 1) * 0.5, 10.0); 
  }

  // Advance to the next level
  void _goToNextLevel() {
    setState(() {
      level++;
      score += 50 * level; // Increase bonus for higher levels
      _resetBall();
      _createBlocks();
    });
  }

  // Main game loop update function
  void _update() {
    if (isPaused || isGameOver || !isGameStarted) return;

    setState(() {
      // --- Ball Movement ---
      ballX += ballDX;
      ballY += ballDY;

      // --- Wall Collisions ---
      if (ballX <= 0 && ballDX < 0) { // Hit left wall
        ballDX = -ballDX * (0.95 + (Random().nextDouble() * 0.1));
        ballX = 0; // Prevent sticking
      } else if (ballX >= screenWidth - ballSize && ballDX > 0) { // Hit right wall
         ballDX = -ballDX * (0.95 + (Random().nextDouble() * 0.1));
         ballX = screenWidth - ballSize; // Prevent sticking
      }
      
      if (ballY <= 0 && ballDY < 0) { // Hit top wall
        ballDY = -ballDY; 
        ballY = 0; // Prevent sticking
      }

      // --- Paddle Collision ---
      // Predict next frame position for better collision detection
      Rect nextBallRect = Rect.fromLTWH(ballX + ballDX, ballY + ballDY, ballSize, ballSize);
      Rect paddleRect = Rect.fromLTWH(paddleX, screenHeight - paddleHeight, paddleWidth, paddleHeight); // Paddle at bottom edge
      
      if (nextBallRect.overlaps(paddleRect) && ballDY > 0) {
        double hitPos = (ballX + ballSize / 2 - (paddleX + paddleWidth / 2)) / paddleWidth;
        
        ballDY = -ballDY.abs(); // Bounce up
        ballDX = hitPos * 10.0; // Angle based on hit position
        ballDX = ballDX.clamp(-12.0, 12.0); // Cap horizontal speed
        if (ballDX.abs() < 2.0) ballDX = ballDX.sign * 2.0; // Min horizontal speed
        
        // Adjust ball position to sit exactly on the paddle to prevent sinking
        ballY = screenHeight - paddleHeight - ballSize; 

        score += 5; 
      }

      // --- Block Collisions ---
      // Iterate backwards for safe removal during iteration
      for (int i = blocks.length - 1; i >= 0; i--) {
         Rect blockRect = blocks[i].rect;
         // Use predicted nextBallRect for collision check
         // Rect nextBallRect = Rect.fromLTWH(ballX + ballDX, ballY + ballDY, ballSize, ballSize); // Already defined above paddle collision

         if (nextBallRect.overlaps(blockRect)) { 
            // Bounce logic first
            final intersection = blockRect.intersect(nextBallRect); 
            if (intersection.width < intersection.height) {
               ballDX = -ballDX;
               ballX += ballDX > 0 ? intersection.width : -intersection.width; 
            } else {
               ballDY = -ballDY;
               ballY += ballDY > 0 ? intersection.height : -intersection.height;
            }
            // Decrement health only when removing
            blocks[i].health--; 
            if (blocks[i].health <= 0) {
               score += 10 * level; // Award points
               blocks.removeAt(i); // Remove immediately now that health is confirmed <= 0
            } else {
               // If block not destroyed, just update its state (e.g., color change if needed)
               // Currently no visual change for damaged blocks, but could add here.
            }
            
            // Removed break; Allow checking multiple collisions per frame (e.g., corners)
         }
      }
      // Block removal is now handled inside the loop

      // --- Ball Out of Bounds ---
      if (ballY >= screenHeight) { 
        lives--;
        
        if (lives <= 0) {
          // --- Game Over ---
          _gameTimer?.cancel();
          isGameOver = true; 

          if (_userId != null && score > 0) {
             if (score > highScore) {
               highScore = score; // Update local display
             }
             // Save high score using the correct arguments
             _highscoreService.saveUserHighScore('Pong', score).catchError((error) {
               print("Error saving high score: $error");
               // Optionally show a message to the user if saving fails
             });
          } else {
             if (score > highScore) {
               highScore = score;
             }
          }
        } else {
          // --- Lose Life ---
          isPaused = true; 
          Timer(const Duration(milliseconds: 1500), () { // Longer pause
             if (!mounted) return; 
             setState(() {
                 _resetBall();
                 isPaused = false; 
             });
          });
        }
      }

      // --- Level Cleared ---
      if (isGameStarted && !isGameOver && blocks.isEmpty) {
         isPaused = true;
         Timer(const Duration(milliseconds: 1500), () { // Longer pause
            if (!mounted) return; 
            _goToNextLevel(); 
            setState(() {
               isPaused = false; 
            });
         });
      }
    });
  }
  
  // Move paddle based on delta X
  void _handlePaddleMove(double dx) {
    if (isPaused || isGameOver || !isGameStarted) return; 
    setState(() {
      paddleX += dx;
      paddleX = paddleX.clamp(0.0, screenWidth - paddleWidth); 
    });
  }
  
  // Start dragging paddle
  void _handlePanStart(DragStartDetails details) {
    if (!isGameStarted || isPaused || isGameOver) return;
    // Use global position for initial tap, convert to local for reference
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    dragStartX = renderBox.globalToLocal(details.globalPosition).dx - paddleX;
    isDragging = true;
  }

  // Update paddle position during drag
  void _handlePanUpdate(DragUpdateDetails details) {
    if (!isDragging || !isGameStarted || isPaused || isGameOver) return;
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    double currentX = renderBox.globalToLocal(details.globalPosition).dx;
    
    setState(() {
       paddleX = (currentX - (dragStartX ?? 0)).clamp(0.0, screenWidth - paddleWidth);
    });
  }

  // End dragging paddle
  void _handlePanEnd(DragEndDetails details) {
    isDragging = false;
    dragStartX = null;
  }

  // Build the main widget tree
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), 
      appBar: AppBar(
        title: const Text(
          'PONG BREAKOUT',
          style: TextStyle(
            fontFamily: 'joystix_monospace', fontSize: 20, color: Colors.white, letterSpacing: 1.5,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A2E), 
        elevation: 0,
        centerTitle: true, 
        actions: [
          IconButton(
            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
            tooltip: isPaused ? 'Resume' : 'Pause',
            onPressed: _togglePause, 
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
             tooltip: 'Restart Game',
            onPressed: _startGame, 
          ),
        ],
      ),
      body: LayoutBuilder( 
        builder: (context, constraints) {
          // Initialize dimensions and game state on first build or resize
          if (!isInitialized || screenWidth != constraints.maxWidth || screenHeight != (constraints.maxHeight - 100)) { // Check height too
             screenWidth = constraints.maxWidth;
             final safePadding = MediaQuery.of(context).padding;
             final appBarHeight = AppBar().preferredSize.height;
             const double controlAreaHeight = 100.0; 
             screenHeight = constraints.maxHeight - appBarHeight - safePadding.top - safePadding.bottom - controlAreaHeight;
             
             // Ensure height is positive
             if (screenHeight < 0) screenHeight = 0;

             // Initialize or re-initialize game if not already started
             if (!isGameStarted && screenWidth > 0 && screenHeight > 0) {
                 WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                       _initializeGame();
                       setState(() {
                          isInitialized = true;
                       });
                    }
                 });
             } else if (isGameStarted && screenWidth > 0 && screenHeight > 0) {
                 // Adjust paddle position if screen resized during game
                 paddleX = paddleX.clamp(0.0, screenWidth - paddleWidth);
             }
          }

          if (!isInitialized || screenHeight <= 0) { // Also check height
            return const Center(child: CircularProgressIndicator());
          }

          // --- Main Game Layout ---
          return Column(
            children: [
              // Status bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                decoration: BoxDecoration(
                  color: const Color(0xFF162447).withOpacity(0.5), 
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  // Use Expanded to allow info boxes to share space flexibly
                  children: [
                    Expanded(child: _buildInfoBox('SCORE', '$score', Icons.star_border)),
                    Expanded(child: _buildInfoBox('LEVEL', '$level', Icons.layers_outlined)),
                    Expanded(child: _buildInfoBox('LIVES', '$lives', Icons.favorite_border)),
                  ],
                ),
              ),

              // Game area
              Expanded(
                child: GestureDetector(
                  onHorizontalDragStart: _handlePanStart,
                  onHorizontalDragUpdate: _handlePanUpdate,
                  onHorizontalDragEnd: _handlePanEnd,
                  child: ClipRect( 
                    child: Container(
                      width: screenWidth, 
                      height: screenHeight, 
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [ const Color(0xFF1A1A2E), const Color(0xFF162447).withOpacity(0.8) ],
                        ),
                        border: Border.all( color: Colors.cyanAccent.withOpacity(0.2), width: 1),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none, // Allow paddle glow to extend slightly
                        children: [
                          // Background grid
                          CustomPaint( size: Size(screenWidth, screenHeight), painter: GridPainter()),
                          
                          // Blocks
                          ...blocks.map((block) => Positioned(
                            left: block.rect.left, top: block.rect.top,
                            width: block.rect.width, height: block.rect.height,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  colors: [ block.color.withOpacity(0.9), block.color.withOpacity(0.6) ],
                                ),
                                borderRadius: BorderRadius.circular(3), 
                                border: Border.all( color: Colors.white.withOpacity(0.2), width: 0.5),
                                boxShadow: [ BoxShadow( color: block.color.withOpacity(0.4), blurRadius: 4, offset: const Offset(1, 1)) ],
                              ),
                              child: block.health > 1 ? Center( child: Icon( Icons.bolt, color: Colors.white.withOpacity(0.7), size: block.rect.height * 0.5)) : null,
                            ),
                          )),
                          
                          // Ball
                          if (isGameStarted && !isGameOver)
                            Positioned(
                              left: ballX, top: ballY,
                              child: AnimatedBuilder( // Use builder only for scale
                                animation: _ballPulseAnimation,
                                builder: (context, child) => Transform.scale(scale: _ballPulseAnimation.value, child: child),
                                child: Container( // Static part of the ball
                                  width: ballSize, height: ballSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient( colors: [ Colors.white, Colors.grey[300]! ]),
                                    boxShadow: [ BoxShadow( color: Colors.cyanAccent.withOpacity(0.7), blurRadius: 8, spreadRadius: 1)],
                                  ),
                                ),
                              ),
                            ),
                          
                          // Paddle
                          if (isGameStarted)
                             Positioned(
                                left: paddleX, bottom: 0, // Position paddle at the very bottom
                                child: AnimatedBuilder(
                                   animation: _paddleGlowAnimation,
                                   builder: (context, child) {
                                      return Container(
                                         width: paddleWidth, height: paddleHeight,
                                         decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                               begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                               colors: [ Colors.cyanAccent.withOpacity(0.9), Colors.blueAccent.withOpacity(0.9) ],
                                            ),
                                            borderRadius: BorderRadius.circular(paddleHeight / 2), 
                                            boxShadow: [
                                               BoxShadow( 
                                                  color: Colors.cyanAccent.withOpacity(0.6), 
                                                  blurRadius: _paddleGlowAnimation.value * 1.5, 
                                                  spreadRadius: _paddleGlowAnimation.value / 3,
                                               ),
                                            ],
                                         ),
                                      );
                                   }
                                ),
                             ),
                          
                          // Overlays
                          if (!isGameStarted && !isGameOver) _buildStartGameOverlay(),
                          if (isGameOver) _buildGameOverOverlay(),
                          if (isPaused && !isGameOver) _buildPauseOverlay(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Controls Area
              Container(
                height: 100, 
                color: const Color(0xFF1A1A2E), // Match background
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton( Icons.arrow_back, () => _handlePaddleMove(-30)),
                    const SizedBox(width: 60), 
                    _buildControlButton( Icons.arrow_forward, () => _handlePaddleMove(30)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Helper Widgets for UI Elements ---

  Widget _buildInfoBox(String label, String value, IconData icon) {
    return Column( 
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.cyanAccent.withOpacity(0.8), size: 18),
        const SizedBox(height: 4),
        Text( label, style: TextStyle( color: Colors.white.withOpacity(0.7), fontSize: 10, fontFamily: 'joystix_monospace', letterSpacing: 1.0)),
        const SizedBox(height: 2),
        Text( value, style: const TextStyle( color: Colors.white, fontSize: 16, fontFamily: 'joystix_monospace', fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent, 
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30), 
        splashColor: Colors.cyanAccent.withOpacity(0.3), 
        highlightColor: Colors.cyanAccent.withOpacity(0.1), 
        child: Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle, 
            gradient: LinearGradient( colors: [ Colors.cyanAccent.withOpacity(0.5), Colors.blueAccent.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border.all( color: Colors.cyanAccent.withOpacity(0.4), width: 1),
            boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          child: Icon( icon, color: Colors.white, size: 30),
        ),
      ),
    );
  } 

  // --- Overlay Widgets ---

  Widget _buildStartGameOverlay() {
    return Positioned.fill( // Use Positioned.fill to cover the Stack
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [ const Color(0xFF1A1A2E).withOpacity(0.9), const Color(0xFF162447).withOpacity(0.95)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration( shape: BoxShape.circle, color: Colors.cyanAccent.withOpacity(0.1), border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2)),
                child: Icon( Icons.rocket_launch_outlined, size: 50, color: Colors.cyanAccent),
              ),
              const SizedBox(height: 25),
              const Text( 'PONG BREAKOUT', style: TextStyle( color: Colors.white, fontSize: 26, fontFamily: 'joystix_monospace', fontWeight: FontWeight.bold, letterSpacing: 3, shadows: [ Shadow( blurRadius: 10.0, color: Colors.cyanAccent, offset: Offset(0, 0))])),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent, foregroundColor: const Color(0xFF1A1A2E), 
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                  shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(30)), 
                  elevation: 5, shadowColor: Colors.cyanAccent.withOpacity(0.5),
                ),
                child: const Text( 'START', style: TextStyle( fontSize: 18, fontFamily: 'joystix_monospace', fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
              const SizedBox(height: 30),
              Text( 'Swipe or use arrows\nto control the paddle', style: TextStyle( color: Colors.white.withOpacity(0.6), fontSize: 12, fontFamily: 'joystix_monospace', letterSpacing: 1.0), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [ const Color(0xFF1A1A2E).withOpacity(0.9), const Color(0xFF162447).withOpacity(0.95)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Text( // GAME OVER Text
                'GAME OVER',
                style: TextStyle( // Removed const
                  color: Colors.redAccent, fontSize: 32, fontFamily: 'joystix_monospace', fontWeight: FontWeight.bold,
                  shadows: [ Shadow( blurRadius: 8.0, color: Colors.redAccent.withOpacity(0.7), offset: const Offset(0, 0))],
                ),
              ),
            const SizedBox(height: 30),
            Text(
              'Swipe or use arrows\nto control the paddle', 
              style: TextStyle(
                color: Colors.white.withOpacity(0.6), 
                fontSize: 11, // Reduced font size slightly
                fontFamily: 'joystix_monospace',
                letterSpacing: 0.8, // Reduced letter spacing slightly
              ),
              textAlign: TextAlign.center,
            ),
              const SizedBox(height: 40),
              ElevatedButton( // Play Again Button
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent, foregroundColor: const Color(0xFF1A1A2E),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(30)), 
                  elevation: 5, shadowColor: Colors.cyanAccent.withOpacity(0.5),
                ),
                child: const Text( 'PLAY AGAIN', style: TextStyle( fontSize: 16, fontFamily: 'joystix_monospace', fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
     return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [ const Color(0xFF1A1A2E).withOpacity(0.9), const Color(0xFF162447).withOpacity(0.95)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Text( // PAUSED Text
                'PAUSED',
                style: TextStyle( // Removed const
                  color: Colors.white, fontSize: 32, fontFamily: 'joystix_monospace', fontWeight: FontWeight.bold, letterSpacing: 2.0,
                  shadows: [ Shadow( blurRadius: 8.0, color: Colors.white.withOpacity(0.5), offset: const Offset(0, 0))],
                ),
              ),
              const SizedBox(height: 40),
              Row( // Pause Buttons Row
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reduce padding and font size slightly to prevent overflow on smaller screens
                  ElevatedButton.icon( // Resume Button
                    icon: const Icon(Icons.play_arrow, size: 18), label: const Text('RESUME'),
                    onPressed: _togglePause,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent, foregroundColor: const Color(0xFF1A1A2E),
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12), // Reduced padding
                      shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(30)),
                      textStyle: const TextStyle( fontSize: 12, fontFamily: 'joystix_monospace', fontWeight: FontWeight.bold, letterSpacing: 1.0), // Reduced font size
                      elevation: 5, shadowColor: Colors.greenAccent.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 20), // Reduced spacing
                  ElevatedButton.icon( // Restart Button
                    icon: const Icon(Icons.refresh, size: 18), label: const Text('RESTART'),
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent, foregroundColor: const Color(0xFF1A1A2E),
                       padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12), // Reduced padding
                      shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(30)),
                       textStyle: const TextStyle( fontSize: 12, fontFamily: 'joystix_monospace', fontWeight: FontWeight.bold, letterSpacing: 1.0), // Reduced font size
                      elevation: 5, shadowColor: Colors.orangeAccent.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Helper Classes ---

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
      ..color = Colors.cyanAccent.withOpacity(0.05) 
      ..strokeWidth = 0.5;

    const double spacing = 20.0; 

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
