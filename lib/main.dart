import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'firebase_options.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/highscores/highscores_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Flag to track Firebase initialization
  bool firebaseInitialized = false;
  
  try {
    // Initialize Firebase with your project configuration
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    print("Firebase successfully initialized");
  } catch (e) {
    print("Failed to initialize Firebase: $e");
    // Continue with the app but in offline mode
  }
  
  // Catch any uncaught Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('FlutterError: ${details.exception}');
  };

  // Catch any errors that occur during widget building
  ErrorWidget.builder = (FlutterErrorDetails details) {
    print('ErrorWidget: ${details.exception}');
    return Container(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: Colors.red,
        child: Center(
          child: Text(
            'An error occurred: ${details.exception}',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  // Handle uncaught asynchronous errors
  PlatformDispatcher.instance.onError = (error, stack) {
    print('PlatformDispatcher error: $error\n$stack');
    return true;
  };
  
  runApp(MyApp(firebaseInitialized: firebaseInitialized));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  
  const MyApp({super.key, this.firebaseInitialized = false});

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
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapper(firebaseInitialized: firebaseInitialized),
        '/auth': (context) => AuthWrapper(requireAuth: true, firebaseInitialized: firebaseInitialized),
        '/highscores': (context) => HighScoresScreen(firebaseInitialized: firebaseInitialized),
        '/profile': (context) => const ProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}