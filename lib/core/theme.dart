import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF7B4DFF);
  static const primaryDark = Color(0xFF5B34D6);
  static const primaryLight = Color(0xFFEFE9FF);
  static const background = Color(0xFFF7F6FB);
  static const textDark = Color(0xFF1F1B3A);
  static const textMuted = Color(0xFF7A7794);
  static const border = Color(0xFFE6E3F2);

  static const amberBg = Color(0xFFFFEFC7);
  static const amberFg = Color(0xFFB7791F);
  static const greenBg = Color(0xFFDDF7E8);
  static const greenFg = Color(0xFF1E9E5A);
  static const redBg = Color(0xFFFFE3E3);
  static const redFg = Color(0xFFE04848);
  static const blueBg = Color(0xFFE3EEFF);
  static const blueFg = Color(0xFF3B7BEA);
}

BoxDecoration cardDecoration({Color color = Colors.white, double radius = 16}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF1F1B3A).withValues(alpha: 0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
  );
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.textDark,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.primary),
      errorBorder: border(AppColors.redFg),
      focusedErrorBorder: border(AppColors.redFg),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
