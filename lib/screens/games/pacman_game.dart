import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class PacmanGame extends StatefulWidget {
  const PacmanGame({super.key});

  @override
  _PacmanGameState createState() => _PacmanGameState();
}

class _PacmanGameState extends State<PacmanGame> with SingleTickerProviderStateMixin {
  static const int rows = 15;
  static const int columns = 15;
  
  // Grid values:
  // 0: empty path
  // 1: wall
  // 2: dot
  // 3: power pellet
  List<List<int>> grid = [];
  
  // Positions
  int pacmanRow = 1;
  int pacmanCol = 1;
  bool pacmanMouthOpen = true;
  
  // Ghosts
  List<Ghost> ghosts = [];
  
  // Game state
  int score = 0;
  int lives = 3;
  bool gameOver = false;
  bool gameWon = false;
  bool isPaused = false;
  Timer? gameTimer;
  String currentDirection = 'right';
  String nextDirection = 'right';
  
  // Animation controller for pacman mouth
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          pacmanMouthOpen = !pacmanMouthOpen;
        });
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          pacmanMouthOpen = !pacmanMouthOpen;
        });
        _animationController.forward();
      }
    });
    _animationController.forward();
    
    initializeGame();
  }
  
  @override
  void dispose() {
    gameTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
  
  void initializeGame() {
    // Initialize grid with a simple maze
    initializeGrid();
    
    // Initialize ghosts
    ghosts = [
      Ghost(row: 7, col: 7, color: Colors.red),
      Ghost(row: 7, col: 8, color: Colors.pink),
      Ghost(row: 8, col: 7, color: Colors.cyan),
      Ghost(row: 8, col: 8, color: Colors.orange),
    ];
    
    // Start game loop
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!isPaused && !gameOver && !gameWon) {
        updateGame();
      }
    });
  }
  
  void initializeGrid() {
    grid = List.generate(rows, (_) => List.filled(columns, 0));
    
    // Create border walls
    for (int i = 0; i < rows; i++) {
      grid[i][0] = 1;
      grid[i][columns - 1] = 1;
    }
    for (int i = 0; i < columns; i++) {
      grid[0][i] = 1;
      grid[rows - 1][i] = 1;
    }
    
    // Add some internal walls to create a maze
    // Horizontal walls
    addWall(2, 2, 5);
    addWall(2, 9, 12);
    addWall(4, 4, 10);
    addWall(7, 2, 5);
    addWall(7, 9, 12);
    addWall(10, 4, 10);
    addWall(12, 2, 5);
    addWall(12, 9, 12);
    
    // Vertical walls
    addVerticalWall(2, 2, 5);
    addVerticalWall(2, 9, 12);
    addVerticalWall(5, 4, 6);
    addVerticalWall(5, 8, 10);
    addVerticalWall(9, 4, 6);
    addVerticalWall(9, 8, 10);
    addVerticalWall(12, 2, 5);
    addVerticalWall(12, 9, 12);
    
    // Add dots and power pellets to empty spaces
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        // If it's an empty cell, add a dot
        if (grid[i][j] == 0) {
          grid[i][j] = 2; // Dot
        }
      }
    }
    
    // Add power pellets in corners
    if (grid[1][1] == 2) grid[1][1] = 3;
    if (grid[1][columns - 2] == 2) grid[1][columns - 2] = 3;
    if (grid[rows - 2][1] == 2) grid[rows - 2][1] = 3;
    if (grid[rows - 2][columns - 2] == 2) grid[rows - 2][columns - 2] = 3;
    
    // Clear starting position for Pacman
    grid[1][1] = 0;
    
    // Clear center for ghosts
    grid[7][7] = 0;
    grid[7][8] = 0;
    grid[8][7] = 0;
    grid[8][8] = 0;
  }
  
  void addWall(int row, int startCol, int endCol) {
    for (int col = startCol; col <= endCol; col++) {
      grid[row][col] = 1;
    }
  }
  
  void addVerticalWall(int col, int startRow, int endRow) {
    for (int row = startRow; row <= endRow; row++) {
      grid[row][col] = 1;
    }
  }
  
  void updateGame() {
    // Apply the next direction if possible
    if (canMove(pacmanRow, pacmanCol, nextDirection)) {
      currentDirection = nextDirection;
    }
    
    // Move Pacman based on the current direction
    movePacman();
    
    // Check for collisions with dots or power pellets
    checkCollision();
    
    // Move ghosts
    moveGhosts();
    
    // Check for ghost collisions
    checkGhostCollisions();
    
    // Check if all dots are gone
    checkWinCondition();
    
    setState(() {});
  }
  
  bool canMove(int row, int col, String direction) {
    switch (direction) {
      case 'up':
        return row > 0 && grid[row - 1][col] != 1;
      case 'down':
        return row < rows - 1 && grid[row + 1][col] != 1;
      case 'left':
        return col > 0 && grid[row][col - 1] != 1;
      case 'right':
        return col < columns - 1 && grid[row][col + 1] != 1;
      default:
        return false;
    }
  }
  
  void movePacman() {
    switch (currentDirection) {
      case 'up':
        if (canMove(pacmanRow, pacmanCol, 'up')) {
          pacmanRow--;
        }
        break;
      case 'down':
        if (canMove(pacmanRow, pacmanCol, 'down')) {
          pacmanRow++;
        }
        break;
      case 'left':
        if (canMove(pacmanRow, pacmanCol, 'left')) {
          pacmanCol--;
        }
        break;
      case 'right':
        if (canMove(pacmanRow, pacmanCol, 'right')) {
          pacmanCol++;
        }
        break;
    }
  }
  
  void checkCollision() {
    if (pacmanRow >= 0 && pacmanRow < rows && pacmanCol >= 0 && pacmanCol < columns) {
      if (grid[pacmanRow][pacmanCol] == 2) {
        // Eat dot
        grid[pacmanRow][pacmanCol] = 0;
        score += 10;
      } else if (grid[pacmanRow][pacmanCol] == 3) {
        // Eat power pellet
        grid[pacmanRow][pacmanCol] = 0;
        score += 50;
        
        // Make ghosts vulnerable
        for (Ghost ghost in ghosts) {
          ghost.isVulnerable = true;
        }
        
        // Schedule ghosts to return to normal after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              for (Ghost ghost in ghosts) {
                ghost.isVulnerable = false;
              }
            });
          }
        });
      }
    }
  }
  
  void moveGhosts() {
    Random random = Random();
    
    for (Ghost ghost in ghosts) {
      List<String> possibleDirections = [];
      
      // Check if ghost can move in each direction
      if (canMove(ghost.row, ghost.col, 'up')) possibleDirections.add('up');
      if (canMove(ghost.row, ghost.col, 'down')) possibleDirections.add('down');
      if (canMove(ghost.row, ghost.col, 'left')) possibleDirections.add('left');
      if (canMove(ghost.row, ghost.col, 'right')) possibleDirections.add('right');
      
      // Remove opposite direction to avoid too much back-and-forth
      if (ghost.direction == 'up' && possibleDirections.contains('down')) {
        possibleDirections.remove('down');
      } else if (ghost.direction == 'down' && possibleDirections.contains('up')) {
        possibleDirections.remove('up');
      } else if (ghost.direction == 'left' && possibleDirections.contains('right')) {
        possibleDirections.remove('right');
      } else if (ghost.direction == 'right' && possibleDirections.contains('left')) {
        possibleDirections.remove('left');
      }
      
      // Choose a random direction if possible
      if (possibleDirections.isNotEmpty) {
        ghost.direction = possibleDirections[random.nextInt(possibleDirections.length)];
      }
      
      // Move ghost based on its direction
      switch (ghost.direction) {
        case 'up':
          ghost.row--;
          break;
        case 'down':
          ghost.row++;
          break;
        case 'left':
          ghost.col--;
          break;
        case 'right':
          ghost.col++;
          break;
      }
    }
  }
  
  void checkGhostCollisions() {
    for (Ghost ghost in ghosts) {
      if (ghost.row == pacmanRow && ghost.col == pacmanCol) {
        if (ghost.isVulnerable) {
          // Eat ghost
          score += 200;
          resetGhost(ghost);
        } else {
          // Ghost eats Pacman
          lives--;
          if (lives <= 0) {
            setState(() {
              gameOver = true;
              gameTimer?.cancel();
            });
          } else {
            // Reset Pacman position
            pacmanRow = 1;
            pacmanCol = 1;
          }
        }
      }
    }
  }
  
  void resetGhost(Ghost ghost) {
    // Reset ghost to center
    ghost.row = 7 + (ghosts.indexOf(ghost) ~/ 2);
    ghost.col = 7 + (ghosts.indexOf(ghost) % 2);
    ghost.isVulnerable = false;
  }
  
  void checkWinCondition() {
    bool dotsRemaining = false;
    
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        if (grid[i][j] == 2 || grid[i][j] == 3) {
          dotsRemaining = true;
          break;
        }
      }
      if (dotsRemaining) break;
    }
    
    if (!dotsRemaining) {
      setState(() {
        gameWon = true;
        gameTimer?.cancel();
      });
    }
  }
  
  void togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }
  
  void restartGame() {
    setState(() {
      pacmanRow = 1;
      pacmanCol = 1;
      currentDirection = 'right';
      nextDirection = 'right';
      score = 0;
      lives = 3;
      gameOver = false;
      gameWon = false;
      isPaused = false;
    });
    
    initializeGame();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'PACMAN',
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
            onPressed: togglePause,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: restartGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Score and lives panel
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Score
                  Flexible(
                    flex: 2,
                    child: Text(
                      'SCORE: $score',
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontFamily: 'joystix_monospace',
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Lives
                  Flexible(
                    flex: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              lives,
                              (index) => const Padding(
                                padding: EdgeInsets.only(left: 2.0),
                                child: Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Game board
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: columns / rows,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue,
                        width: 2,
                      ),
                      color: Colors.black,
                    ),
                    child: Stack(
                      children: [
                        // Grid
                        _buildGrid(),
                        
                        // Game over overlay
                        if (gameOver) _buildGameOverOverlay(),
                        
                        // Game won overlay
                        if (gameWon) _buildGameWonOverlay(),
                        
                        // Pause overlay
                        if (isPaused) _buildPauseOverlay(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(Icons.arrow_upward, () {
                        nextDirection = 'up';
                      }),
                    ],
                  ),
                  // Left, Right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(Icons.arrow_back, () {
                        nextDirection = 'left';
                      }),
                      const SizedBox(width: 50),
                      _buildControlButton(Icons.arrow_forward, () {
                        nextDirection = 'right';
                      }),
                    ],
                  ),
                  // Down
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(Icons.arrow_downward, () {
                        nextDirection = 'down';
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGrid() {
    return CustomPaint(
      painter: PacmanGridPainter(
        grid: grid,
        pacmanRow: pacmanRow,
        pacmanCol: pacmanCol,
        pacmanMouthOpen: pacmanMouthOpen,
        pacmanDirection: currentDirection,
        ghosts: ghosts,
      ),
      size: Size.infinite,
    );
  }
  
  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: Colors.yellow,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.yellow,
          size: 32,
        ),
        onPressed: onPressed,
      ),
    );
  }
  
  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.red,
                fontSize: 28,
                fontFamily: 'joystix_monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Score: $score',
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 20,
                fontFamily: 'joystix_monospace',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: restartGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'PLAY AGAIN',
                style: TextStyle(
                  fontFamily: 'joystix_monospace',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGameWonOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'YOU WIN!',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 28,
                fontFamily: 'joystix_monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Score: $score',
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 20,
                fontFamily: 'joystix_monospace',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: restartGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'PLAY AGAIN',
                style: TextStyle(
                  fontFamily: 'joystix_monospace',
                  fontSize: 16,
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
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: togglePause,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'RESUME',
                style: TextStyle(
                  fontFamily: 'joystix_monospace',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Ghost {
  int row;
  int col;
  Color color;
  String direction;
  bool isVulnerable;
  
  Ghost({
    required this.row,
    required this.col,
    required this.color,
    this.direction = 'up',
    this.isVulnerable = false,
  });
}

class PacmanGridPainter extends CustomPainter {
  final List<List<int>> grid;
  final int pacmanRow;
  final int pacmanCol;
  final bool pacmanMouthOpen;
  final String pacmanDirection;
  final List<Ghost> ghosts;
  
  PacmanGridPainter({
    required this.grid,
    required this.pacmanRow,
    required this.pacmanCol,
    required this.pacmanMouthOpen,
    required this.pacmanDirection,
    required this.ghosts,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / grid[0].length;
    final cellHeight = size.height / grid.length;
    
    // Draw grid
    for (int row = 0; row < grid.length; row++) {
      for (int col = 0; col < grid[row].length; col++) {
        final value = grid[row][col];
        final rect = Rect.fromLTWH(
          col * cellWidth,
          row * cellHeight,
          cellWidth,
          cellHeight,
        );
        
        // Draw walls
        if (value == 1) {
          canvas.drawRect(
            rect,
            Paint()..color = Colors.blue,
          );
        }
        
        // Draw dots
        else if (value == 2) {
          final dotRadius = cellWidth * 0.1;
          canvas.drawCircle(
            Offset(
              rect.left + rect.width / 2,
              rect.top + rect.height / 2,
            ),
            dotRadius,
            Paint()..color = Colors.white,
          );
        }
        
        // Draw power pellets
        else if (value == 3) {
          final pelletRadius = cellWidth * 0.2;
          canvas.drawCircle(
            Offset(
              rect.left + rect.width / 2,
              rect.top + rect.height / 2,
            ),
            pelletRadius,
            Paint()..color = Colors.white,
          );
        }
      }
    }
    
    // Draw Pacman
    final pacmanRect = Rect.fromLTWH(
      pacmanCol * cellWidth,
      pacmanRow * cellHeight,
      cellWidth,
      cellHeight,
    );
    
    if (pacmanMouthOpen) {
      // Draw with open mouth
      final radius = cellWidth * 0.4;
      final center = Offset(
        pacmanRect.left + pacmanRect.width / 2,
        pacmanRect.top + pacmanRect.height / 2,
      );
      
      double startAngle = 0.4;
      double sweepAngle = 2 * pi - 0.8;
      
      if (pacmanDirection == 'right') {
        startAngle = 0.4;
      } else if (pacmanDirection == 'down') {
        startAngle = pi / 2 + 0.4;
      } else if (pacmanDirection == 'left') {
        startAngle = pi + 0.4;
      } else if (pacmanDirection == 'up') {
        startAngle = 3 * pi / 2 + 0.4;
      }
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        Paint()..color = Colors.yellow,
      );
    } else {
      // Draw as full circle (mouth closed)
      canvas.drawCircle(
        Offset(
          pacmanRect.left + pacmanRect.width / 2,
          pacmanRect.top + pacmanRect.height / 2,
        ),
        cellWidth * 0.4,
        Paint()..color = Colors.yellow,
      );
    }
    
    // Draw ghosts
    for (Ghost ghost in ghosts) {
      final ghostRect = Rect.fromLTWH(
        ghost.col * cellWidth,
        ghost.row * cellHeight,
        cellWidth,
        cellHeight,
      );
      
      final ghostCenter = Offset(
        ghostRect.left + ghostRect.width / 2,
        ghostRect.top + ghostRect.height / 2,
      );
      
      // Ghost body (upper half is semicircle, lower half is wavy)
      final ghostBodyRect = Rect.fromLTWH(
        ghostRect.left + ghostRect.width * 0.1,
        ghostRect.top + ghostRect.height * 0.1,
        ghostRect.width * 0.8,
        ghostRect.height * 0.6,
      );
      
      // Draw the ghost body
      final ghostPaint = Paint()
        ..color = ghost.isVulnerable ? Colors.blue : ghost.color;
      
      // Draw the semicircle top
      canvas.drawArc(
        ghostBodyRect,
        pi,
        pi,
        true,
        ghostPaint,
      );
      
      // Draw the lower rectangle
      canvas.drawRect(
        Rect.fromLTWH(
          ghostBodyRect.left,
          ghostBodyRect.top + ghostBodyRect.height / 2,
          ghostBodyRect.width,
          ghostBodyRect.height / 2,
        ),
        ghostPaint,
      );
      
      // Draw eyes
      if (!ghost.isVulnerable) {
        final eyeRadius = cellWidth * 0.1;
        final leftEyeCenter = Offset(
          ghostCenter.dx - eyeRadius * 1.5,
          ghostCenter.dy - eyeRadius,
        );
        final rightEyeCenter = Offset(
          ghostCenter.dx + eyeRadius * 1.5,
          ghostCenter.dy - eyeRadius,
        );
        
        // Eye whites
        canvas.drawCircle(
          leftEyeCenter,
          eyeRadius,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          rightEyeCenter,
          eyeRadius,
          Paint()..color = Colors.white,
        );
        
        // Pupils
        canvas.drawCircle(
          leftEyeCenter,
          eyeRadius * 0.5,
          Paint()..color = Colors.black,
        );
        canvas.drawCircle(
          rightEyeCenter,
          eyeRadius * 0.5,
          Paint()..color = Colors.black,
        );
      } else {
        // Vulnerable ghost has different eyes
        final textPainter = TextPainter(
          text: TextSpan(
            text: '?',
            style: TextStyle(
              color: Colors.white,
              fontSize: cellWidth * 0.5,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            ghostCenter.dx - textPainter.width / 2,
            ghostCenter.dy - textPainter.height / 2,
          ),
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 