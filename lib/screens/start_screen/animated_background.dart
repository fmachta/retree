import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int numParticles = 30;
  final double imageSize = 40.0;
  late List<ParticleData> particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    
    // Initialize particles with random positions and data
    _initializeParticles();
  }

  void _initializeParticles() {
    final random = math.Random();
    particles = List.generate(numParticles, (index) {
      // Randomize particle properties
      return ParticleData(
        initialX: random.nextDouble(),
        initialY: random.nextDouble(),
        size: 20.0 + random.nextDouble() * 30,
        speed: 0.2 + random.nextDouble() * 0.6,
        direction: random.nextDouble() * 2 * math.pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.1,
        type: random.nextInt(5), // 0: pacman, 1: ghost, 2: space invader, 3: tetris block, 4: joystick
        color: [
          Colors.greenAccent,
          Colors.purpleAccent,
          Colors.pinkAccent,
          Colors.blueAccent,
          Colors.yellowAccent,
        ][random.nextInt(5)],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Grid background
        CustomPaint(
          size: Size(screenSize.width, screenSize.height),
          painter: GridPainter(),
        ),
        
        // Animated particles
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: particles.map((particle) {
                // Calculate position based on time and particle properties
                final progress = (_controller.value * particle.speed) % 1.0;
                final angle = particle.direction + _controller.value * particle.rotationSpeed;
                
                // Create cyclical movement pattern
                final x = screenSize.width * 
                    (particle.initialX + 0.3 * math.sin(progress * 2 * math.pi + angle));
                final y = screenSize.height * 
                    (particle.initialY + 0.3 * math.cos(progress * 2 * math.pi + angle));
                
                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: 0.4 + 0.3 * math.sin(progress * 2 * math.pi),
                    child: _buildParticleWidget(particle),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildParticleWidget(ParticleData particle) {
    return Transform.rotate(
      angle: _controller.value * particle.rotationSpeed * 2 * math.pi,
      child: Container(
        width: particle.size,
        height: particle.size,
        decoration: BoxDecoration(
          color: Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: particle.color.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: _getParticleIcon(particle),
      ),
    );
  }
  
  Widget _getParticleIcon(ParticleData particle) {
    switch (particle.type) {
      case 0: // Pacman
        return Icon(Icons.brightness_1, color: particle.color);
      case 1: // Ghost
        return Icon(Icons.blur_on, color: particle.color);
      case 2: // Space invader
        return Icon(Icons.bug_report, color: particle.color);
      case 3: // Tetris block
        return Container(
          decoration: BoxDecoration(
            color: particle.color.withOpacity(0.7),
            border: Border.all(color: Colors.white, width: 1),
          ),
        );
      case 4: // Joystick
        return Icon(Icons.sports_esports, color: particle.color);
      default:
        return Icon(Icons.star, color: particle.color);
    }
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purpleAccent.withOpacity(0.15)
      ..strokeWidth = 1.0;
      
    // Draw horizontal lines
    final horizontalSpacing = size.height / 20;
    for (int i = 0; i <= 20; i++) {
      final y = i * horizontalSpacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw vertical lines
    final verticalSpacing = size.width / 20;
    for (int i = 0; i <= 20; i++) {
      final x = i * verticalSpacing;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Draw perspective lines (horizon effect)
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radiusPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.1)
      ..strokeWidth = 1.0;
      
    for (int i = 1; i <= 10; i++) {
      final radius = i * size.width / 10;
      canvas.drawCircle(Offset(centerX, centerY), radius, radiusPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ParticleData {
  final double initialX;
  final double initialY;
  final double size;
  final double speed;
  final double direction;
  final double rotationSpeed;
  final int type;
  final Color color;

  ParticleData({
    required this.initialX,
    required this.initialY,
    required this.size,
    required this.speed,
    required this.direction,
    required this.rotationSpeed,
    required this.type,
    required this.color,
  });
}