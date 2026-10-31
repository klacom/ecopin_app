import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand: Primary ──────────────────────────────────
  static const Color primary = Color(0xFF0052CC);
  static const Color primaryLight = Color(0xFF0052CC);
  static const Color primaryDark = Color(0xFF0052CC);

  // ── Brand: Secondary ────────────────────────────────
  static const Color secondaryLight = Color(0xFF60A5FA);
  static const Color secondaryDark = Color(0xFF60A5FA);

  // ── Brand: Accent ───────────────────────────────────
  static const Color accent = Color(0xFF0052CC);
  static const Color accentBlue = Color(0xFF0052CC);
  static const Color linkDark = Color(0xFF82B6FF);
  static const Color environmentalLight = Color(0xFF27754D);
  static const Color environmentalDark = Color(0xFF83CBA0);

  // ── Neutrals ──────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF17212E);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryLight = Color(0xFF59636E);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);

  /// Light canvas for the citizen tab shell only (pushed screens stay on [backgroundLight]).
  static const Color tabCanvasLight = Color(0xFFF2F4F7);

  // ── Status ────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  // Text, icons and badges read AppStatusColors from the theme instead.
  /// Bright amber for fills under dark text only (sync chips, warning snackbars).
  static const Color warningFill = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);
  /// Light-theme information blue; white text on it passes 4.5:1.
  static const Color info = Color(0xFF0369A1);

  // ── Surface / Elevated ────────────────────────────────────
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1C1C1C);

  // ── Divider / Border ──────────────────────────────────────
  static const Color dividerLight = Color(0xFFE5E9EE);
  static const Color dividerDark = Color(0xFF333333);

  // ── Shadows ───────────────────────────────────────────────
  static const Color shadowCard = Color(0x1A000000);
  static const Color shadowFloating = Color(0x33000000);
  static const Color shadowDialog = Color(0x40000000);

  // ── Spacing tokens (8-point grid) ────────────────────────
  static const double spaceXS = 4;
  static const double spaceSM = 8;
  static const double spaceMD = 16;
  static const double spaceLG = 24;
  static const double spaceXL = 32;
  static const double spaceXXL = 48;
  static const double spaceXXXL = 64;

  // ── Border Radius tokens ──────────────────────────────────
  static const double radiusButton = 999;
  static const double radiusCard = 16;
  static const double radiusInput = 12;
  static const double radiusDialog = 24;
  static const double radiusChip = 999;
}
