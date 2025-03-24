import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class TetrisGame extends StatefulWidget {
  const TetrisGame({super.key});

  @override
  _TetrisGameState createState() => _TetrisGameState();
}

class _TetrisGameState extends State<TetrisGame> {
  // Game board dimensions
  static const int rows = 20;
  static const int cols = 10;
  
  // Game state
  List<List<int>> board = List.generate(rows, (_) => List.filled(cols, 0));
  List<List<int>> currentPiece = [];
  int currentPieceRow = 0;
  int currentPieceCol = 0;
  int currentPieceId = 0;
  int score = 0;
  int level = 1;
  int linesCleared = 0;
  bool isGameOver = false;
  bool isPaused = false;
  Timer? gameTimer;
  
  // Drop speed (milliseconds)
  int dropSpeed = 500;
  
  // Tetromino shapes with colors (1-7)
  final List<List<List<int>>> tetrominos = [
    // I-Piece (cyan)
    [
      [0, 0, 0, 0],
      [1, 1, 1, 1],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ],
    // J-Piece (blue)
    [
      [2, 0, 0],
      [2, 2, 2],
      [0, 0, 0],
    ],
    // L-Piece (orange)
    [
      [0, 0, 3],
      [3, 3, 3],
      [0, 0, 0],
    ],
    // O-Piece (yellow)
    [
      [4, 4],
      [4, 4],
    ],
    // S-Piece (green)
    [
      [0, 5, 5],
      [5, 5, 0],
      [0, 0, 0],
    ],
    // T-Piece (purple)
    [
      [0, 6, 0],
      [6, 6, 6],
      [0, 0, 0],
    ],
    // Z-Piece (red)
    [
      [7, 7, 0],
      [0, 7, 7],
      [0, 0, 0],
    ],
  ];
  
  // Colors for tetrominos
  final List<Color> tetrominoColors = [
    Colors.black,           // Empty
    Colors.cyanAccent,      // I-Piece
    Colors.blue,            // J-Piece
    Colors.orange,          // L-Piece
    Colors.yellow,          // O-Piece
    Colors.green,           // S-Piece
    Colors.purple,          // T-Piece
    Colors.red,             // Z-Piece
  ];

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      board = List.generate(rows, (_) => List.filled(cols, 0));
      score = 0;
      level = 1;
      linesCleared = 0;
      isGameOver = false;
      isPaused = false;
      dropSpeed = 500;
    });
    spawnNewPiece();
    
    gameTimer?.cancel();
    gameTimer = Timer.periodic(Duration(milliseconds: dropSpeed), (timer) {
      if (!isPaused && !isGameOver) {
        moveDown();
      }
    });
  }

  void spawnNewPiece() {
    final random = Random();
    final randomIndex = random.nextInt(tetrominos.length);
    
    currentPieceId = randomIndex + 1;
    currentPiece = List.from(tetrominos[randomIndex]);
    currentPieceRow = 0;
    currentPieceCol = cols ~/ 2 - currentPiece[0].length ~/ 2;
    
    // Check if the new piece conflicts with existing blocks
    if (!isValidMove(currentPieceRow, currentPieceCol, currentPiece)) {
      setState(() {
        isGameOver = true;
        gameTimer?.cancel();
      });
    }
  }

  bool isValidMove(int row, int col, List<List<int>> piece) {
    for (int r = 0; r < piece.length; r++) {
      for (int c = 0; c < piece[r].length; c++) {
        if (piece[r][c] != 0) {
          // Check boundaries
          if (row + r < 0 || row + r >= rows || col + c < 0 || col + c >= cols) {
            return false;
          }
          // Check collision with other pieces
          if (board[row + r][col + c] != 0) {
            return false;
          }
        }
      }
    }
    return true;
  }

  void moveLeft() {
    if (isValidMove(currentPieceRow, currentPieceCol - 1, currentPiece)) {
      setState(() {
        currentPieceCol--;
      });
    }
  }

  void moveRight() {
    if (isValidMove(currentPieceRow, currentPieceCol + 1, currentPiece)) {
      setState(() {
        currentPieceCol++;
      });
    }
  }

  void moveDown() {
    if (isValidMove(currentPieceRow + 1, currentPieceCol, currentPiece)) {
      setState(() {
        currentPieceRow++;
      });
    } else {
      // Lock piece in place
      lockPiece();
      // Check for completed lines
      clearLines();
      // Spawn a new piece
      spawnNewPiece();
    }
  }

  void hardDrop() {
    while (isValidMove(currentPieceRow + 1, currentPieceCol, currentPiece)) {
      setState(() {
        currentPieceRow++;
      });
    }
    // Lock piece in place
    lockPiece();
    // Check for completed lines
    clearLines();
    // Spawn a new piece
    spawnNewPiece();
  }

  void rotate() {
    List<List<int>> rotatedPiece = _rotateMatrix(currentPiece);
    if (isValidMove(currentPieceRow, currentPieceCol, rotatedPiece)) {
      setState(() {
        currentPiece = rotatedPiece;
      });
    }
  }

  List<List<int>> _rotateMatrix(List<List<int>> matrix) {
    int n = matrix.length;
    List<List<int>> rotated = List.generate(n, (_) => List.filled(n, 0));
    
    // Transpose
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        rotated[i][j] = matrix[j][i];
      }
    }
    
    // Reverse each row
    for (int i = 0; i < n; i++) {
      rotated[i] = rotated[i].reversed.toList();
    }
    
    return rotated;
  }

  void lockPiece() {
    for (int r = 0; r < currentPiece.length; r++) {
      for (int c = 0; c < currentPiece[r].length; c++) {
        if (currentPiece[r][c] != 0) {
          board[currentPieceRow + r][currentPieceCol + c] = currentPieceId;
        }
      }
    }
  }

  void clearLines() {
    List<int> linesToClear = [];
    
    // Check for completed lines
    for (int r = 0; r < rows; r++) {
      bool isLineComplete = true;
      for (int c = 0; c < cols; c++) {
        if (board[r][c] == 0) {
          isLineComplete = false;
          break;
        }
      }
      if (isLineComplete) {
        linesToClear.add(r);
      }
    }
    
    if (linesToClear.isEmpty) return;
    
    setState(() {
      // Clear lines and shift down
      for (int lineIndex in linesToClear.reversed) {
        board.removeAt(lineIndex);
        board.insert(0, List.filled(cols, 0));
      }
      
      // Update score
      linesCleared += linesToClear.length;
      
      // Calculate score based on number of lines cleared
      switch (linesToClear.length) {
        case 1:
          score += 100 * level;
          break;
        case 2:
          score += 300 * level;
          break;
        case 3:
          score += 500 * level;
          break;
        case 4:
          score += 800 * level; // Tetris!
          break;
      }
      
      // Update level (every 10 lines)
      level = (linesCleared ~/ 10) + 1;
      
      // Increase speed with level
      dropSpeed = 500 - (level - 1) * 50;
      if (dropSpeed < 100) dropSpeed = 100;
      
      // Reset timer with new speed
      gameTimer?.cancel();
      gameTimer = Timer.periodic(Duration(milliseconds: dropSpeed), (timer) {
        if (!isPaused && !isGameOver) {
          moveDown();
        }
      });
    });
  }

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'TETRIS',
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
            onPressed: startGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Score panel
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoBox('SCORE', '$score'),
                  _buildInfoBox('LEVEL', '$level'),
                  _buildInfoBox('LINES', '$linesCleared'),
                ],
              ),
            ),
            
            // Game board
            Expanded(
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: AspectRatio(
                    aspectRatio: cols / rows,
                    child: Stack(
                      children: [
                        // Board
                        _buildBoard(),
                        
                        // Current piece
                        _buildCurrentPiece(),
                        
                        // Game over overlay
                        if (isGameOver) _buildGameOverOverlay(),
                        
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildControlButton(Icons.arrow_left, moveLeft),
                  _buildControlButton(Icons.arrow_drop_down, hardDrop),
                  _buildControlButton(Icons.refresh, rotate),
                  _buildControlButton(Icons.arrow_right, moveRight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: Colors.purpleAccent,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'joystix_monospace',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'joystix_monospace',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows * cols,
      itemBuilder: (context, index) {
        final row = index ~/ cols;
        final col = index % cols;
        final cellValue = board[row][col];
        
        return Container(
          decoration: BoxDecoration(
            color: cellValue == 0 ? Colors.black54 : tetrominoColors[cellValue],
            border: Border.all(
              color: Colors.black45,
              width: 0.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentPiece() {
    if (isGameOver || isPaused) return Container();
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows * cols,
        itemBuilder: (context, index) {
          final row = index ~/ cols;
          final col = index % cols;
          
          // Check if this cell belongs to the current piece
          bool isCellInCurrentPiece = false;
          int pieceColorId = 0;
          
          if (row >= currentPieceRow && 
              row < currentPieceRow + currentPiece.length &&
              col >= currentPieceCol && 
              col < currentPieceCol + currentPiece[0].length) {
            final pieceRow = row - currentPieceRow;
            final pieceCol = col - currentPieceCol;
            
            if (pieceRow >= 0 && pieceRow < currentPiece.length &&
                pieceCol >= 0 && pieceCol < currentPiece[pieceRow].length) {
              pieceColorId = currentPiece[pieceRow][pieceCol];
              if (pieceColorId != 0) {
                isCellInCurrentPiece = true;
              }
            }
          }
          
          return isCellInCurrentPiece
              ? Container(
                  decoration: BoxDecoration(
                    color: tetrominoColors[currentPieceId],
                    border: Border.all(
                      color: Colors.black45,
                      width: 0.5,
                    ),
                  ),
                )
              : Container();
        },
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
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'joystix_monospace',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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
                backgroundColor: Colors.purple,
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

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: Colors.purpleAccent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 32,
        ),
        onPressed: onPressed,
      ),
    );
  }
} 