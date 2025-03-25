import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../services/highscore_service.dart';
import '../../services/auth_service.dart';
import '../highscores/highscores_screen.dart';

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  _SnakeGameState createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> with TickerProviderStateMixin {
  static const int gridSize = 20;
  
  // Services
  final HighScoreService _highScoreService = HighScoreService();
  final AuthService _authService = AuthService();
  
  // Game state
  late int gridWidth;
  late int gridHeight;
  late double cellSize;
  List<Offset> snake = [];
  Offset? food;
  String direction = 'right';
  String newDirection = 'right';
  Timer? gameTimer;
  bool isGameOver = false;
  bool isGameStarted = false;
  bool isPaused = false;
  int score = 0;
  int highScore = 0;
  int speed = 200;
  static const int speedIncrement = 10;
  static const int minSpeed = 70;
  int level = 1;
  int lastLevelUpScore = 0;
  bool _isSavingScore = false;
  
  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _snakeController;
  late Animation<Color?> _snakeColorAnimation;
  
  // Snake color gradient
  final List<Color> snakeGradient = [
    Colors.greenAccent,
    Colors.green,
    Colors.lightGreen,
  ];
  
  // Food types with scores
  final List<Map<String, dynamic>> foodTypes = [
    {'color': Colors.redAccent, 'score': 10, 'probability': 0.7},
    {'color': Colors.orangeAccent, 'score': 20, 'probability': 0.2},
    {'color': Colors.purpleAccent, 'score': 50, 'probability': 0.1},
  ];
  
  // Current food properties
  Map<String, dynamic> currentFood = {
    'color': Colors.redAccent,
    'score': 10,
    'type': 0,
  };
  
  // Controller for swipe detection
  double startX = 0;
  double startY = 0;
  double updateX = 0;
  double updateY = 0;
  
  @override
  void initState() {
    super.initState();
    
    // Load high score
    _loadHighScore();
    
    // Set up pulsing animation for food
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Set up color animation for snake head
    _snakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    
    _snakeColorAnimation = ColorTween(
      begin: Colors.greenAccent,
      end: Colors.lightGreenAccent,
    ).animate(CurvedAnimation(
      parent: _snakeController,
      curve: Curves.easeInOut,
    ));
    
    // Empty snake initially
    snake = [];
    food = null;
  }
  
  @override
  void dispose() {
    gameTimer?.cancel();
    _pulseController.dispose();
    _snakeController.dispose();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    try {
      if (_authService.currentUser != null) {
        final userHighScore = await _highScoreService.getUserGameHighScore('Snake');
        if (userHighScore != null) {
          setState(() {
            highScore = userHighScore;
          });
        }
      }
    } catch (e) {
      print('Error loading high score: $e');
    }
  }

  void _startGame() {
    if (!isGameStarted) {
      setState(() {
        isGameStarted = true;
        isPaused = false;
        isGameOver = false;
        snake = [Offset((gridWidth / 2).floor().toDouble(), (gridHeight / 2).floor().toDouble())];
        direction = 'right';
        newDirection = 'right';
        score = 0;
        level = 1;
        lastLevelUpScore = 0;
        speed = 200; // Initial speed
        _spawnFood();
      });
      
      _restartGameTimer();
    }
  }

  void _restartGameTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(Duration(milliseconds: speed), (timer) {
      if (!isGameOver && !isPaused) _moveSnake();
    });
  }

  void _spawnFood() {
    // Choose food type based on probability
    double rand = Random().nextDouble();
    double cumulativeProbability = 0;
    
    for (int i = 0; i < foodTypes.length; i++) {
      cumulativeProbability += foodTypes[i]['probability'];
      if (rand <= cumulativeProbability) {
        currentFood = {
          'color': foodTypes[i]['color'],
          'score': foodTypes[i]['score'],
          'type': i,
        };
        break;
      }
    }
    
    // Place food in random location
    Random randPos = Random();
    Offset newFood;
    do {
      newFood = Offset(
        randPos.nextInt(gridWidth).toDouble(),
        randPos.nextInt(gridHeight).toDouble(),
      );
    } while (snake.contains(newFood));
    
    setState(() => food = newFood);
  }

  void _moveSnake() {
    if (!mounted) return;
    
    setState(() {
      // Update direction only at movement time to prevent multiple turns in single frame
      direction = newDirection;
      
      Offset head = snake.first;
      Offset newHead;

      // Determine new head based on direction
      switch (direction) {
        case 'up':
          newHead = Offset(head.dx, head.dy - 1);
          break;
        case 'down':
          newHead = Offset(head.dx, head.dy + 1);
          break;
        case 'left':
          newHead = Offset(head.dx - 1, head.dy);
          break;
        case 'right':
          newHead = Offset(head.dx + 1, head.dy);
          break;
        default:
          newHead = head;
      }

      // Check for wall collision with wrap-around
      if (newHead.dx < 0) {
        newHead = Offset(gridWidth - 1, newHead.dy);
      } else if (newHead.dx >= gridWidth) {
        newHead = Offset(0, newHead.dy);
      } else if (newHead.dy < 0) {
        newHead = Offset(newHead.dx, gridHeight - 1);
      } else if (newHead.dy >= gridHeight) {
        newHead = Offset(newHead.dx, 0);
      }
      
      // Check for self collision
      if (snake.contains(newHead)) {
        isGameOver = true;
        _isSavingScore = true;
        gameTimer?.cancel();
        
        // Update high score
        if (score > highScore) {
          highScore = score;
          
          // Save to Firebase if authenticated
          if (_authService.currentUser != null) {
            _saveHighScore();
          } else {
            // Just update local state if not authenticated
            _isSavingScore = false;
          }
        } else {
          _isSavingScore = false;
        }
        
        return;
      }

      snake.insert(0, newHead);
      if (newHead == food) {
        // Increase score and speed based on food type
        score += currentFood['score'] as int;
        
        // Update level based on score
        final newLevel = (score / 100).floor() + 1;
        if (newLevel > level) {
          level = newLevel;
          lastLevelUpScore = score;
          
          // Increase speed (decrease delay)
          if (speed > minSpeed) {
            speed = speed - speedIncrement;
            _restartGameTimer();
          }
        }
        
        // Spawn new food
        _spawnFood();
      } else {
        // Remove tail if not eating
        snake.removeLast();
      }
    });
  }

  // Add a separate method to save high score asynchronously
  Future<void> _saveHighScore() async {
    try {
      await _highScoreService.saveUserHighScore('Snake', score);
    } catch (e) {
      print('Error saving high score: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingScore = false;
        });
      }
    }
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    if (isGameOver || !isGameStarted || isPaused) return;
    startY = details.globalPosition.dy;
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (isGameOver || !isGameStarted || isPaused) return;
    updateY = details.globalPosition.dy;
    
    if (updateY - startY > 20 && direction != 'up') {
      newDirection = 'down';
    } else if (startY - updateY > 20 && direction != 'down') {
      newDirection = 'up';
    }
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    if (isGameOver || !isGameStarted || isPaused) return;
    startX = details.globalPosition.dx;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (isGameOver || !isGameStarted || isPaused) return;
    updateX = details.globalPosition.dx;
    
    if (updateX - startX > 20 && direction != 'left') {
      newDirection = 'right';
    } else if (startX - updateX > 20 && direction != 'right') {
      newDirection = 'left';
    }
  }

  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  int _updateSpeed() {
    // Calculate game speed - higher level = faster speed (lower delay)
    int minSpeed = 100; // Fastest speed (minimum delay)
    int maxSpeed = 200; // Slowest speed (maximum delay)
    int speedReduction = (level * 10); // Reduce delay by 10ms per level
    
    // Ensure speed doesn't go below minimum
    int newSpeed = maxSpeed - speedReduction;
    return newSpeed < minSpeed ? minSpeed : newSpeed;
  }
  
  void _advanceGame() {
    // Update speed based on level
    speed = _updateSpeed();
    
    // Increment level every 50 points
    if (score > 0 && score % 50 == 0 && score > lastLevelUpScore) {
      setState(() {
        level = (score ~/ 50) + 1;
        lastLevelUpScore = score;
      });
    }
    
    // Move snake if game is active
    if (!isGameOver && !isPaused) {
      _moveSnake();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'SNAKE',
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
            onPressed: _startGame,
          ),
        ],
      ),
      body: Column(
        children: [
          // Score panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBox('SCORE', '$score'),
                _buildInfoBox('LEVEL', '$level'),
                _buildInfoBox('HIGH', '$highScore'),
              ],
            ),
          ),
          
          // Game board
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(
                      color: Colors.greenAccent.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onVerticalDragStart: _handleVerticalDragStart,
                    onVerticalDragUpdate: _handleVerticalDragUpdate,
                    onHorizontalDragStart: _handleHorizontalDragStart,
                    onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Initialize grid dimensions
                        gridWidth = gridSize;
                        gridHeight = gridSize;
                        cellSize = constraints.maxWidth / gridWidth;
                        
                        return Stack(
                          children: [
                            // Background grid lines
                            CustomPaint(
                              size: Size(constraints.maxWidth, constraints.maxHeight),
                              painter: GridPainter(gridWidth, gridHeight),
                            ),
                            
                            // Food
                            if (food != null && isGameStarted)
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Positioned(
                                    left: food!.dx * cellSize,
                                    top: food!.dy * cellSize,
                                    child: Transform.scale(
                                      scale: _pulseAnimation.value,
                                      child: _buildFoodWidget(cellSize),
                                    ),
                                  );
                                },
                              ),
                            
                            // Snake
                            ...snake.asMap().entries.map((entry) {
                              final index = entry.key;
                              final segment = entry.value;
                              
                              if (index == 0) {
                                // Snake head with animation
                                return AnimatedBuilder(
                                  animation: _snakeColorAnimation,
                                  builder: (context, child) {
                                    return Positioned(
                                      left: segment.dx * cellSize,
                                      top: segment.dy * cellSize,
                                      width: cellSize,
                                      height: cellSize,
                                      child: _buildSnakeHead(cellSize),
                                    );
                                  },
                                );
                              } else {
                                // Snake body
                                return Positioned(
                                  left: segment.dx * cellSize,
                                  top: segment.dy * cellSize,
                                  width: cellSize,
                                  height: cellSize,
                                  child: _buildSnakeBody(cellSize, index, snake.length),
                                );
                              }
                            }),
                            
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
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Control buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(
                      Icons.keyboard_arrow_up,
                      () {
                        if (direction != 'down') {
                          newDirection = 'up';
                        }
                      },
                    ),
                  ],
                ),
                // Left, Right
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(
                      Icons.keyboard_arrow_left,
                      () {
                        if (direction != 'right') {
                          newDirection = 'left';
                        }
                      },
                    ),
                    const SizedBox(width: 80),
                    _buildControlButton(
                      Icons.keyboard_arrow_right,
                      () {
                        if (direction != 'left') {
                          newDirection = 'right';
                        }
                      },
                    ),
                  ],
                ),
                // Down
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(
                      Icons.keyboard_arrow_down,
                      () {
                        if (direction != 'up') {
                          newDirection = 'down';
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.greenAccent, width: 1),
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
              color: Colors.greenAccent,
              fontSize: 16,
              fontFamily: 'joystix_monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSnakeHead(double size) {
    BoxShape shape;
    
    // Determine head shape based on direction
    switch (direction) {
      case 'up':
        shape = BoxShape.rectangle;
        break;
      case 'down':
        shape = BoxShape.rectangle;
        break;
      case 'left':
        shape = BoxShape.rectangle;
        break;
      case 'right':
        shape = BoxShape.rectangle;
        break;
      default:
        shape = BoxShape.rectangle;
    }
    
    return Container(
      margin: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: _snakeColorAnimation.value,
        shape: shape,
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.5),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: _getHeadIcon(direction, size),
    );
  }
  
  Widget _getHeadIcon(String direction, double size) {
    IconData icon;
    double iconSize = size * 0.6;
    
    switch (direction) {
      case 'up':
        icon = Icons.arrow_drop_up;
        break;
      case 'down':
        icon = Icons.arrow_drop_down;
        break;
      case 'left':
        icon = Icons.arrow_left;
        break;
      case 'right':
        icon = Icons.arrow_right;
        break;
      default:
        icon = Icons.arrow_right;
    }
    
    return Center(
      child: Icon(
        icon,
        size: iconSize,
        color: Colors.black87,
      ),
    );
  }
  
  Widget _buildSnakeBody(double size, int index, int snakeLength) {
    // Calculate color based on position in snake
    double colorPosition = index / (snakeLength > 1 ? snakeLength - 1 : 1);
    int colorIndex = (colorPosition * (snakeGradient.length - 1)).floor();
    Color color = snakeGradient[colorIndex];
    
    return Container(
      margin: EdgeInsets.all(size * 0.15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 3,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }
  
  Widget _buildFoodWidget(double size) {
    // Different food types have different appearances
    Widget foodWidget;
    
    switch (currentFood['type']) {
      case 0: // Basic food (apple)
        foodWidget = Container(
          width: size * 0.7,
          height: size * 0.7,
          decoration: BoxDecoration(
            color: currentFood['color'],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: currentFood['color'].withOpacity(0.5),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
        );
        break;
      case 1: // Special food (orange)
        foodWidget = Icon(
          Icons.star,
          color: currentFood['color'],
          size: size * 0.7,
        );
        break;
      case 2: // Rare food (power-up)
        foodWidget = Container(
          width: size * 0.7,
          height: size * 0.7,
          decoration: BoxDecoration(
            color: currentFood['color'],
            borderRadius: BorderRadius.circular(size * 0.15),
            boxShadow: [
              BoxShadow(
                color: currentFood['color'].withOpacity(0.8),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.flash_on,
            color: Colors.white,
          ),
        );
        break;
      default:
        foodWidget = Container(
          width: size * 0.7,
          height: size * 0.7,
          decoration: BoxDecoration(
            color: currentFood['color'],
            shape: BoxShape.circle,
          ),
        );
    }
    
    return Center(child: foodWidget);
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
              color: Colors.greenAccent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: Colors.greenAccent,
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
              Icons.pets,
              size: 60,
              color: Colors.greenAccent,
            ),
            const SizedBox(height: 20),
            const Text(
              'SNAKE',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 32,
                fontFamily: 'joystix_monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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
              'Swipe or use controls to move',
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
              Column(
                children: [
                  const Text(
                    'NEW HIGH SCORE!',
                    style: TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 16,
                      fontFamily: 'joystix_monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_authService.currentUser == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/auth');
                        },
                        icon: const Icon(Icons.login, color: Colors.greenAccent, size: 16),
                        label: const Text(
                          'SIGN IN TO SAVE',
                          style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                        ),
                      ),
                    ),
                  if (_isSavingScore)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.greenAccent,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Saving score...',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 12,
                            fontFamily: 'joystix_monospace',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
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
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/highscores', arguments: 'Snake');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'LEADERBOARD',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'joystix_monospace',
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
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
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

class GridPainter extends CustomPainter {
  final int gridWidth;
  final int gridHeight;
  
  GridPainter(this.gridWidth, this.gridHeight);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.1)
      ..strokeWidth = 0.5;
    
    final cellWidth = size.width / gridWidth;
    final cellHeight = size.height / gridHeight;
    
    // Draw vertical lines
    for (int i = 0; i <= gridWidth; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Draw horizontal lines
    for (int i = 0; i <= gridHeight; i++) {
      final y = i * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}