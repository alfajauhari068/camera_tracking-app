import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

/// Tema aplikasi dengan dark mode lembut
/// Colors:
/// - Primary: Navy (#1a237e)
/// - Accent: Neon green (#00e676)
/// - Background: Dark grey (#121212)
/// - Card: Slightly lighter (#1e1e1e)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera Tracking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Use dark brightness
        brightness: Brightness.dark,
        // Primary color - Navy
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1a237e),  // Navy blue
          secondary: Color(0xFF00e676), // Neon green accent
          surface: Color(0xFF1e1e1e),   // Card background
        ),
        // Scaffold background - Dark grey
        scaffoldBackgroundColor: const Color(0xFF121212),
        // Use Material 3
        useMaterial3: true,
        // AppBar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1a237e),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
// Card theme
        cardTheme: const CardThemeData(
          color: Color(0xFF1e1e1e),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        // Elevated button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1a237e),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Text theme - clean sans-serif, readable outdoor
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      // ========================================================================
      // ROUTING CONFIGURATION
      // ========================================================================
      
      // Option 1: Menggunakan named routes biasa
      routes: getAppRoutes(),
      initialRoute: AppRoutes.home,

      // Option 2: Menggunakan onGenerateRoute untuk lebih advanced
      // (uncomment jika ingin menggunakan route arguments parsing)
      // onGenerateRoute: onGenerateRoute,
    );
  }
}
