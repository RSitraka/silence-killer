import 'package:flutter/material.dart';

/// Palette pastel joyeuse de l'application.
class AppColors {
  static const background = Color(0xFFFFF6EC);
  static const ink = Color(0xFF3D2C5C); // texte principal (violet très foncé)
  static const inkSoft = Color(0xFF7A6A99);

  static const pink = Color(0xFFFF8FB8);
  static const yellow = Color(0xFFFFD66B);
  static const mint = Color(0xFF7EE3B4);
  static const sky = Color(0xFF7CC8FF);
  static const lavender = Color(0xFFB9A2FF);
  static const peach = Color(0xFFFFB38A);
  static const coral = Color(0xFFFF7B7B);

  // Couleurs des rôles : bleu ciel / vert pour les citoyens,
  // violet / rouge pour les assassins.
  static const citizenBlue = Color(0xFF4FB8F5);
  static const citizenGreen = Color(0xFF3FCF8E);
  static const assassinPurple = Color(0xFF7C3AED);
  static const assassinRed = Color(0xFFE11D48);

  static const dead = Color(0xFFBDB8C7);

  /// Couleurs des avatars des joueurs (une par joueur, en boucle).
  static const avatarPalette = [
    Color(0xFFFF9CC2),
    Color(0xFF8FD3FF),
    Color(0xFFFFD66B),
    Color(0xFF9BEBC4),
    Color(0xFFC6B3FF),
    Color(0xFFFFB38A),
    Color(0xFF7EDFE6),
    Color(0xFFF7A8F0),
    Color(0xFFB8E986),
    Color(0xFFFFC4A3),
  ];

  static Color avatar(int index) => avatarPalette[index % avatarPalette.length];
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Fredoka',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.lavender,
      surface: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.ink,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Fredoka',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Color(0xFFEDE3F7), width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: AppColors.lavender, width: 3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: AppColors.coral, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: AppColors.coral, width: 3),
      ),
    ),
  );
}
