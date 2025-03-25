import 'package:flutter/material.dart';
import 'animated_background.dart'; // Ensure this exists
import 'gameselectionscreen.dart';
import '../highscores/highscores_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/auth_service.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _controller;
  late Animation<double> _titleAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _titleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Show login icon or user profile icon
          IconButton(
            icon: Icon(
              _authService.currentUser != null ? Icons.person : Icons.login,
              color: Colors.greenAccent,
            ),
            tooltip: _authService.currentUser != null ? 'Profile' : 'Sign In',
            onPressed: () {
              if (_authService.currentUser != null) {
                // Navigate to profile
                Navigator.pushNamed(context, '/profile');
              } else {
                // Navigate to auth screen
                Navigator.pushNamed(context, '/auth');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 
                              MediaQuery.of(context).padding.top - 
                              MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.05),
                      
                      // Logo and Title
                      AnimatedBuilder(
                        animation: _titleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _titleAnimation.value,
                            child: Opacity(
                              opacity: _titleAnimation.value,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.videogame_asset,
                                    size: screenWidth * 0.15,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(height: 15),
                                  ShaderMask(
                                    shaderCallback: (bounds) {
                                      return LinearGradient(
                                        colors: [
                                          Colors.greenAccent,
                                          Colors.purpleAccent,
                                          Colors.pinkAccent,
                                        ],
                                        tileMode: TileMode.mirror,
                                      ).createShader(bounds);
                                    },
                                    child: Text(
                                      'RETREE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.11,
                                        fontFamily: 'joystix_monospace',
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 2.0,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 10.0,
                                            color: Colors.purpleAccent.withOpacity(0.7),
                                            offset: const Offset(0, 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ARCADE CLASSICS',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: screenWidth * 0.03,
                                      fontFamily: 'joystix_monospace',
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: screenHeight * 0.08),
                      
                      // Buttons
                      AnimatedBuilder(
                        animation: _buttonAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, 50 * (1 - _buttonAnimation.value)),
                            child: Opacity(
                              opacity: _buttonAnimation.value,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildButton(
                                    'START GAME',
                                    Icons.play_arrow,
                                    Colors.greenAccent,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) => const GameSelectionScreen(),
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
                                  ),
                                  const SizedBox(height: 15),
                                  _buildButton(
                                    'SETTINGS',
                                    Icons.settings,
                                    Colors.purpleAccent,
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Settings coming soon!',
                                            style: TextStyle(
                                              fontFamily: 'joystix_monospace',
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: Colors.purpleAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 15),
                                  _buildButton(
                                    'HIGH SCORES',
                                    Icons.emoji_events,
                                    Colors.pinkAccent,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) => const HighScoresScreen(),
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
                                  ),
                                  const SizedBox(height: 15),
                                  _buildButton(
                                    'PROFILE',
                                    Icons.person,
                                    Colors.orangeAccent,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
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
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton.icon(
                                    onPressed: () async {
                                      await _authService.signOut();
                                    },
                                    icon: const Icon(Icons.logout, color: Colors.white70),
                                    label: const Text(
                                      'SIGN OUT',
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: screenHeight * 0.05),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, IconData icon, Color color, {required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(0.6),
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'joystix_monospace',
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}