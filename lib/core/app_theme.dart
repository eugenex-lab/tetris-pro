import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color background = Color(0xFF2C241B); // Dark Wood
  static const Color surface = Color(0xFF3E3226); // Lighter Wood
  static const Color primary = Color(0xFFD7CCC8); // Plank color
  static const Color accent = Color(0xFFFFD180); // Gold/Coin
  static const Color woodDark = Color(0xFF1B1611); // Very Dark Wood
  static const Color woodLight = Color(0xFF8D6E63);

  // Text Styles
  static TextStyle get titleStyle => GoogleFonts.cinzel(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primary,
    shadows: [
      const Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4),
    ],
  );

  static TextStyle get bodyStyle =>
      GoogleFonts.lato(fontSize: 16, color: primary);

  static TextStyle get buttonStyle => GoogleFonts.lato(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: woodDark,
  );

  static TextStyle get techTitleStyle => GoogleFonts.orbitron(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: Colors.redAccent,
    letterSpacing: 4,
    shadows: [
      Shadow(color: Colors.redAccent.withValues(alpha: 0.8), blurRadius: 20),
      const Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4),
    ],
  );

  static TextStyle get techMonoStyle => GoogleFonts.shareTechMono(
    fontSize: 24,
    color: const Color(0xFFFFD54F),
    shadows: [
      Shadow(
        color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
        blurRadius: 10,
      ),
    ],
  );

  static ThemeData get themeData => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: surface,
    ),
    textTheme: TextTheme(headlineLarge: titleStyle, bodyMedium: bodyStyle),
    useMaterial3: true,
  );
}
