import 'package:flutter/material.dart';
import 'screens/start_screen/startscreen.dart'; // Adjust path if in a subdirectory like 'screens/start_screen/startscreen.dart'

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retree',
      theme: ThemeData(
        // Use a dark theme with neon accents for retro feel
        brightness: Brightness.dark,
        primaryColor: Colors.purple[800],
        colorScheme: ColorScheme.dark(
          primary: Colors.purple[800]!,
          secondary: Colors.greenAccent,
          tertiary: Colors.pinkAccent,
          surface: Colors.black,
          background: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'joystix_monospace',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.greenAccent,
                offset: Offset(0, 0),
              ),
            ],
          ),
          titleLarge: TextStyle(color: Colors.white, fontSize: 24),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple[800],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: Colors.greenAccent, width: 2),
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black.withOpacity(0.7),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontFamily: 'joystix_monospace',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      home: const StartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}