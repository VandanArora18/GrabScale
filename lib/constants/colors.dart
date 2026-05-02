import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const deepNavy = Color(0xFF0A0F2C);
  static const background = Color(0xFF0C112E);
  static const electricCyan = Color(0xFF00D4FF);
  static const deepViolet = Color(0xFF7000FF);
  static const softWhite = Color(0xFFF0F4FF);
  static const surface = Color(0xFF0C112E);
  static const surfaceDim = Color(0xFF0C112E);
  static const surfaceBright = Color(0xFF323756);
  static const surfaceContainerLowest = Color(0xFF070B28);
  static const surfaceContainerLow = Color(0xFF141936);
  static const surfaceContainer = Color(0xFF191D3B);
  static const surfaceContainerHigh = Color(0xFF232846);
  static const surfaceContainerHighest = Color(0xFF2E3351);
  static const surfaceVariant = Color(0xFF2E3351);

  static const onSurface = Color(0xFFDEE0FF);
  static const onSurfaceVariant = Color(0xFFBBC9CF);
  static const onBackground = Color(0xFFDEE0FF);

  static const primary = Color(0xFFA8E8FF);
  static const primaryContainer = Color(0xFF00D4FF);
  static const onPrimary = Color(0xFF003642);
  static const onPrimaryContainer = Color(0xFF00586B);
  static const surfaceTint = Color(0xFF3CD7FF);
  static const secondary = Color(0xFFD1BCFF);
  static const secondaryContainer = Color(0xFF7000FF);
  static const onSecondary = Color(0xFF3C0090);

  static const tertiary = Color(0xFFFFD9A1);
  static const tertiaryContainer = Color(0xFFFEB528);
  static const onTertiary = Color(0xFF432C00);

  static const error = Color(0xFFFFB4AB);
  static const errorContainer = Color(0xFF93000A);

  static const outline = Color(0xFF859398);
  static const outlineVariant = Color(0xFF3C494E);

  static Color glassBackground = Colors.white.withOpacity(0.10);
  static Color glassBorder = Colors.white.withOpacity(0.15);
  static Color glassBorderStrong = Colors.white.withOpacity(0.20);

  static const cyanGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF3CD7FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
