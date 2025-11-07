import 'package:flutter/material.dart';

class AppTheme {
  // Neon Colors
  static const Color neonBlue = Color(0xFF00F0FF);
  static const Color neonPurple = Color(0xFFBF00FF);
  static const Color neonPink = Color(0xFFFF00E5);
  static const Color neonGreen = Color(0xFF00FF94);
  static const Color neonYellow = Color(0xFFFFE500);
  static const Color neonOrange = Color(0xFFFF6B00);
  
  // Background Colors
  static const Color darkBg = Color(0xFF0A0E27);
  static const Color cardBg = Color(0xFF1A1F3A);
  static const Color glassBg = Color(0x20FFFFFF);
  
  // Signal Type Colors
  static const Map<String, Color> signalColors = {
    'sine': neonBlue,
    'square': neonPurple,
    'triangle': neonGreen,
    'sawtooth': neonOrange,
  };

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: neonBlue,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      primary: neonBlue,
      secondary: neonPurple,
      surface: cardBg,
      background: darkBg,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: Colors.white70,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: Colors.white60,
        fontSize: 14,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonBlue,
        foregroundColor: darkBg,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );

  // Gradient Backgrounds
  static const LinearGradient neonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonBlue, neonPurple, neonPink],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkBg, Color(0xFF1A1F3A)],
  );

  // Glow Effect
  static BoxShadow neonGlow(Color color, {double blur = 20}) {
    return BoxShadow(
      color: color.withOpacity(0.6),
      blurRadius: blur,
      spreadRadius: blur / 4,
    );
  }

  static List<BoxShadow> multiColorGlow() {
    return [
      neonGlow(neonBlue, blur: 15),
      neonGlow(neonPurple, blur: 20),
      neonGlow(neonPink, blur: 25),
    ];
  }
}
