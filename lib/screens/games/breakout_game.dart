import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BreakoutGame extends StatefulWidget {
  const BreakoutGame({super.key});

  @override
  State<BreakoutGame> createState() => _BreakoutGameState();
}

class _BreakoutGameState extends State<BreakoutGame> with TickerProviderStateMixin {
  late AnimationController _controller;
  late double _paddleX;
  late double _ballX, _ballY;
  late double _ballSpeedX, _ballSpeedY;
  late List<Rect> _bricks;
  int _score = 0;
  bool _gameOver = false;
  bool _gameStarted = false;
  Size _gameAreaSize = Size.zero; // Store the actual game area size

  final double _paddleWidth = 100.0;
  final double _paddleHeight = 20.0;
  final double _ballRadius = 10.0;
  final double _brickWidth = 60.0;
  final double _brickHeight = 20.0;
  final int _bricksPerRow = 5;
  final int _numRows = 4;
  final double _brickSpacing = 4.0;
  final double _initialBallSpeed = 4.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // Roughly 60 FPS
    )..addListener(_updateGame);

    // Focus node to capture keyboard events
    _focusNode = FocusNode();
    // Request focus after the first frame
    // Focus node to capture keyboard events
    _focusNode = FocusNode();
    // Initialization requiring context will happen in didChangeDependencies
    // _resetGame(); // DO NOT call here, context not ready
  }

  late FocusNode _focusNode; // Declare FocusNode
  // bool _isBreakoutInitialized = false; // Track initialization - Replaced by LayoutBuilder

  // Reset game based on the actual game area size
  void _resetGame(Size gameAreaSize) {
    if (!mounted || gameAreaSize == Size.zero) return; // Ensure mounted and size is valid
    _gameAreaSize = gameAreaSize; // Store the size
    _paddleX = (gameAreaSize.width - _paddleWidth) / 2;
    _ballX = gameAreaSize.width / 2;
    _ballY = gameAreaSize.height / 2 + 50; // Position relative to game area height
    _ballSpeedY = _initialBallSpeed;
    _ballSpeedX = _initialBallSpeed * (Random().nextBool() ? 1 : -1);
    _score = 0;
    _gameOver = false;
    _gameStarted = false; // Ensure game stops on reset
    _bricks = _createBricks(gameAreaSize); // Pass the correct size
    if (_controller.isAnimating) {
      _controller.stop(); // Stop animation on reset
    }
    // Trigger a rebuild to show the initial state
    if (mounted) {
      setState(() {});
    }
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   // Initialization is now handled by LayoutBuilder
  // }


  // Create bricks based on the actual game area size
  List<Rect> _createBricks(Size gameAreaSize) {
    List<Rect> bricks = [];
    final double totalBrickWidth = (_brickWidth + _brickSpacing) * _bricksPerRow - _brickSpacing;
    final double startX = (gameAreaSize.width - totalBrickWidth) / 2;
    double currentY = 60.0; // Starting Y position for bricks (relative to game area top)

    for (int row = 0; row < _numRows; row++) {
      double currentX = startX;
      for (int col = 0; col < _bricksPerRow; col++) {
        bricks.add(Rect.fromLTWH(currentX, currentY, _brickWidth, _brickHeight));
        currentX += _brickWidth + _brickSpacing;
      }
      currentY += _brickHeight + _brickSpacing;
    }
    return bricks;
  }

  void _startGame() {
    // Ensure game area size is known before starting
    if (_gameAreaSize == Size.zero) return;

    if (!_gameStarted && !_gameOver) {
      _gameStarted = true;
      _controller.repeat();
    } else if (_gameOver) {
       _resetGame(_gameAreaSize); // Reset with the known game area size
       setState(() {
         // _gameOver = false; // Already handled in _resetGame
         // _gameStarted = false; // Already handled in _resetGame
       });
       // Start animation only after state is set
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted && !_controller.isAnimating) {
           _gameStarted = true; // Mark as started *after* reset
           _controller.repeat();
         }
       });
    }
  }


  void _updateGame() {
    if (!_gameStarted || _gameOver || _gameAreaSize == Size.zero) return;

    // Use the stored _gameAreaSize consistently
    final size = _gameAreaSize;

    // Move ball
    setState(() {
      _ballX += _ballSpeedX;
      _ballY += _ballSpeedY;

      // Wall collisions
      if (_ballX <= _ballRadius || _ballX >= size.width - _ballRadius) {
        _ballSpeedX = -_ballSpeedX;
        _ballX = _ballX.clamp(_ballRadius, size.width - _ballRadius); // Prevent sticking
      }
      if (_ballY <= _ballRadius) {
        _ballSpeedY = -_ballSpeedY;
         _ballY = _ballY.clamp(_ballRadius, size.height); // Prevent sticking
      }

      // Paddle collision - Use gameAreaSize.height
      final paddleRect = Rect.fromLTWH(
          _paddleX, size.height - _paddleHeight - 30, _paddleWidth, _paddleHeight);
    // Define ballRect using current position
    final ballRect = Rect.fromCircle(center: Offset(_ballX, _ballY), radius: _ballRadius);

    // Revised Paddle Collision Logic: Check for overlap in the current frame
    if (_ballSpeedY > 0 && // Moving down
        ballRect.bottom >= paddleRect.top && // Ball bottom edge is at or below paddle top
        ballRect.top < paddleRect.bottom && // Ball top edge is above paddle bottom (prevents detection after passing through)
        ballRect.right > paddleRect.left && // Ball overlaps horizontally
        ballRect.left < paddleRect.right)
    {
        // Collision detected!
        // Calculate hit position relative to paddle center (-1.0 to 1.0)
          // Use the current ballRect for hit position calculation
          double hitPos = (ballRect.center.dx - paddleRect.center.dx) / (paddleRect.width / 2);
          hitPos = hitPos.clamp(-1.0, 1.0); // Clamp value to prevent extreme angles

          // Angle relative to vertical (0 = straight up, positive = right, negative = left)
          // Max bounce angle influence (e.g., 60 degrees = pi/3)
          double influence = pi / 3;
          double bounceAngle = hitPos * influence;

          // Maintain current speed magnitude
          double currentSpeed = sqrt(_ballSpeedX * _ballSpeedX + _ballSpeedY * _ballSpeedY);
          // Optional: Increase speed slightly on paddle hit
          // currentSpeed *= 1.02;

          // New velocity components based on bounce angle
          _ballSpeedX = currentSpeed * sin(bounceAngle);
          _ballSpeedY = -currentSpeed * cos(bounceAngle); // Bounce upwards (negative Y)

          // Reposition ball precisely on top of the paddle to prevent sinking
          // Use paddleRect.top, not the potentially outdated ballY
          _ballY = paddleRect.top - _ballRadius - 0.1; // Place slightly above

          // Optional: Add sound effect or visual feedback here
      }


      // Brick collisions
      // ballRect is already defined above
      Rect? hitBrick;
      for (final brick in List<Rect>.from(_bricks)) { // Iterate over a copy
        if (ballRect.overlaps(brick)) {
          hitBrick = brick;
          _bricks.remove(brick);
          _score++;

          // Determine collision side (simple approach)
          double overlapX = (ballRect.width / 2 + brick.width / 2) - (_ballX - brick.center.dx).abs();
          double overlapY = (ballRect.height / 2 + brick.height / 2) - (_ballY - brick.center.dy).abs();

          if (overlapX >= overlapY) {
            // Horizontal collision likely (hit top/bottom)
            _ballSpeedY = -_ballSpeedY;
             // Move ball slightly away to prevent sticking
            _ballY += _ballSpeedY > 0 ? overlapY : -overlapY;
          } else {
            // Vertical collision likely (hit sides)
            _ballSpeedX = -_ballSpeedX;
             // Move ball slightly away to prevent sticking
            _ballX += _ballSpeedX > 0 ? overlapX : -overlapX;
          }
          break; // Handle one brick collision per frame
        }
      }


      // Game over condition - Use gameAreaSize.height
      if (_ballY >= size.height - _ballRadius) {
        _gameOver = true;
        _gameStarted = false; // Stop the game logic
        _controller.stop();
      }

      // Win condition
      if (_bricks.isEmpty) {
         _gameOver = true; // Or a "You Win!" state
         _gameStarted = false;
         _controller.stop();
         // Consider adding a win message or screen
      }
    });
  }

  void _movePaddle(double dx) {
     if (!_gameStarted || _gameAreaSize == Size.zero) return; // Don't move if not started or size unknown
    // Use the stored _gameAreaSize
    final size = _gameAreaSize;
    setState(() {
      _paddleX = (_paddleX + dx).clamp(0, size.width - _paddleWidth);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose(); // Dispose FocusNode
    super.dispose();
  }

  // @override
  // void dispose() {
  //   _controller.dispose();
  //   _focusNode.dispose(); // Dispose FocusNode
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Outer Scaffold remains
      appBar: AppBar( // AppBar remains part of the Scaffold
        title: const Text('Breakout'),
        actions: [
          Center(child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text('Score: $_score', style: const TextStyle(fontSize: 18)),
          )),
        ],
      ),
      backgroundColor: Colors.black,
      body: RawKeyboardListener(
         focusNode: _focusNode,
         autofocus: true,
         onKey: (RawKeyEvent event) {
           if (event is RawKeyDownEvent) {
             if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
               _movePaddle(-25.0); // Adjust speed as needed
             } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
               _movePaddle(25.0); // Adjust speed as needed
             } else if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter) {
                if (!_gameStarted || _gameOver) {
                  _startGame();
                }
             }
           }
         },
         // Wrap the game area in LayoutBuilder
         child: LayoutBuilder( // LayoutBuilder starts here
           builder: (context, constraints) {
             final newSize = constraints.biggest;
             // Initialize or update size and reset game if necessary
             // Use addPostFrameCallback to avoid setState during build
             if (_gameAreaSize != newSize && newSize != Size.zero) {
               WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (mounted) {
                   // Only reset if game hasn't started or size significantly changed
                   // This prevents resetting during minor layout fluctuations
                   if (!_gameStarted || (_gameAreaSize.width - newSize.width).abs() > 1 || (_gameAreaSize.height - newSize.height).abs() > 1) {
                      _resetGame(newSize);
                      setState(() {}); // Trigger rebuild after reset
                   } else {
                      // Just update the size if game is running
                      _gameAreaSize = newSize;
                   }
                 }
               });
             }

             // Show loading if size is still zero
             if (_gameAreaSize == Size.zero) {
               return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
             }

             // Build the actual game UI using the determined size
             return GestureDetector( // GestureDetector starts here
               onTap: _startGame,
               onHorizontalDragUpdate: (details) {
                 if (_gameStarted) {
                   _movePaddle(details.delta.dx);
                 }
               },
               child: Stack( // Stack starts here
                 children: [
                   // Game Area - Pass the correct size to the painter
                   Positioned.fill(
                     child: CustomPaint(
                       size: _gameAreaSize, // Explicitly provide the size
                       painter: _BreakoutPainter(
                         paddleX: _paddleX,
                         paddleWidth: _paddleWidth,
                         paddleHeight: _paddleHeight,
                         ballX: _ballX,
                         ballY: _ballY,
                         ballRadius: _ballRadius,
                         bricks: _bricks,
                         brickHeight: _brickHeight,
                         brickWidth: _brickWidth,
                       ),
                     ),
                   ),
                   // Game Over / Start Message
                   if (_gameOver || !_gameStarted)
                     Center(
                       child: Container(
                         padding: const EdgeInsets.all(20),
                         decoration: BoxDecoration(
                           color: Colors.black.withOpacity(0.7),
                           borderRadius: BorderRadius.circular(10),
                         ),
                         child: Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Text(
                               _gameOver ? 'Game Over!' : 'Tap or Press Space/Enter to Start',
                               style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                               textAlign: TextAlign.center,
                             ),
                             if (_gameOver) ...[
                               const SizedBox(height: 10),
                               Text(
                                 'Final Score: $_score',
                                 style: const TextStyle(fontSize: 20, color: Colors.white),
                               ),
                               const SizedBox(height: 20),
                               ElevatedButton(
                                 onPressed: _startGame, // Use _startGame which handles reset
                                 child: const Text('Play Again'),
                               )
                             ],
                             if (!_gameStarted && !_gameOver) ... [
                               const SizedBox(height: 15),
                               const Text(
                                 'Use Left/Right Arrows or Drag to Move Paddle',
                                 style: TextStyle(fontSize: 16, color: Colors.white70),
                                 textAlign: TextAlign.center,
                               ),
                             ]
                           ],
                         ),
                       ),
                     ),
                 ],
               ), // Stack ends here
             ); // GestureDetector ends here
           }, // LayoutBuilder builder ends here
         ), // LayoutBuilder ends here
       ), // RawKeyboardListener ends here
    ); // Scaffold ends here
  } // build method ends
} // _BreakoutGameState class ends


// Custom Painter for drawing game elements
class _BreakoutPainter extends CustomPainter {
  final double paddleX;
  final double paddleWidth;
  final double paddleHeight;
  final double ballX;
  final double ballY;
  final double ballRadius;
  final List<Rect> bricks;
  final double brickWidth;
  final double brickHeight;


  _BreakoutPainter({
    required this.paddleX,
    required this.paddleWidth,
    required this.paddleHeight,
    required this.ballX,
    required this.ballY,
    required this.ballRadius,
    required this.bricks,
    required this.brickWidth,
    required this.brickHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintPaddle = Paint()..color = Colors.blue;
    final paintBall = Paint()..color = Colors.yellow;
    final paintBrick = Paint()..color = Colors.red;
    final paintBrickBorder = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;


    // Draw paddle
    final paddleRect = Rect.fromLTWH(
        paddleX, size.height - paddleHeight - 30, paddleWidth, paddleHeight); // Positioned 30px from bottom
    canvas.drawRect(paddleRect, paintPaddle);

    // Draw ball
    canvas.drawCircle(Offset(ballX, ballY), ballRadius, paintBall);

    // Draw bricks
    for (final brick in bricks) {
      canvas.drawRect(brick, paintBrick);
      canvas.drawRect(brick, paintBrickBorder); // Draw border
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Repaint whenever game state changes
    return true;
  }
}
