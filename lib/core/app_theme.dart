// lib/core/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // UNINTER institutional palette
  static const primary      = Color(0xFF1A52A8);
  static const primaryLight = Color(0xFF4A88E8);
  static const primaryDark  = Color(0xFF0D3275);
  static const bg           = Color(0xFFF0F5FC);
  static const card         = Color(0xFFFFFFFF);
  static const surface      = Color(0xFFE3EDF9);
  static const success      = Color(0xFF27AE60);
  static const successLight = Color(0xFFD4EFDF);
  static const warning      = Color(0xFFF39C12);
  static const warningLight = Color(0xFFFEF3CD);
  static const error        = Color(0xFFE74C3C);
  static const text         = Color(0xFF1A2340);
  static const textSub      = Color(0xFF6B7A9B);
  static const divider      = Color(0xFFD0DCF0);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      iconTheme: IconThemeData(color: Colors.white),
      centerTitle: true,
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      labelStyle: const TextStyle(color: AppColors.textSub, fontSize: 14),
      hintStyle: const TextStyle(color: AppColors.textSub),
      prefixIconColor: AppColors.textSub,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 1,
      shadowColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
      side: const BorderSide(color: AppColors.divider),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

// Halloween palette constants (not AppColors — those are Conferencias only)
class HalloweenColors {
  static const bg        = Color(0xFF0D0118);
  static const surface   = Color(0xFF1A0A2E);
  static const card      = Color(0xFF1A0A2E);
  static const primary   = Color(0xFF9C27B0);
  static const secondary = Color(0xFFFF6D00);
  static const text      = Color(0xFFE8D5FF);
  static const textSub   = Color(0xFFD0B8FF);
  static const divider   = Color(0xFF6A0080);
  static const error     = Color(0xFFFF5252);
  static const success   = Color(0xFF66BB6A);
  static const warning   = Color(0xFFFF6D00);
  static const input     = Color(0xFF2D0A4E);
}

ThemeData buildHalloweenTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: HalloweenColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: HalloweenColors.primary,
      secondary: HalloweenColors.secondary,
      surface: HalloweenColors.surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: HalloweenColors.text,
      error: HalloweenColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: HalloweenColors.surface,
      foregroundColor: HalloweenColors.text,
      titleTextStyle: TextStyle(
        color: HalloweenColors.text,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      iconTheme: IconThemeData(color: HalloweenColors.text),
      centerTitle: true,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: HalloweenColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HalloweenColors.input,
      labelStyle: const TextStyle(color: HalloweenColors.textSub, fontSize: 14),
      hintStyle: TextStyle(color: HalloweenColors.textSub.withValues(alpha: 0.6)),
      prefixIconColor: HalloweenColors.textSub,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: HalloweenColors.primary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: HalloweenColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: HalloweenColors.secondary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: HalloweenColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: HalloweenColors.error),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: HalloweenColors.card,
      elevation: 6,
      shadowColor: HalloweenColors.primary.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: HalloweenColors.primary.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    chipTheme: ChipThemeData(
      backgroundColor: HalloweenColors.input,
      labelStyle: const TextStyle(color: HalloweenColors.text, fontSize: 12),
      side: const BorderSide(color: HalloweenColors.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
