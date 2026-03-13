import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color black = Color(0xFF0A0A0A);
  static const Color darkGray = Color(0xFF1A1A1A);
  static const Color mediumGray = Color(0xFF2A2A2A);
  static const Color lightGray = Color(0xFF8A8A8A);
  static const Color silver = Color(0xFFB0B0B0);
  static const Color limeGreen = Color(0xFF8DC63F);
  static const Color limeGreenDark = Color(0xFF6FA832);
  static const Color limeGreenGlow = Color(0xFF9ED64A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF5F5F5);
  static const Color cardWhite = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: offWhite,
      colorScheme: const ColorScheme.light(
        primary: limeGreen,
        secondary: darkGray,
        surface: cardWhite,
        background: offWhite,
      ),
    );
  }
}
