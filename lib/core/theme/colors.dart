import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand: Primary Green ──────────────────────────────────
  static const Color primaryLight = Color(0xFFCCFF00); // Neon Lime
  static const Color primaryDark = Color(0xFFCCFF00);

  // ── Brand: Secondary Green ────────────────────────────────
  static const Color secondaryLight = Color(0xFF000000);
  static const Color secondaryDark = Color(0xFFFFFFFF);

  // ── Brand: Accent Green ───────────────────────────────────
  static const Color accent = Color(0xFFCCFF00);
  static const Color accentBlue = Color(0xFF3300FF);

  // ── Neutrals ──────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);

  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF000000);

  // ── Status ────────────────────────────────────────────────
  static const Color success = Color(0xFFCCFF00);
  static const Color warning = Color(0xFFFFCC00);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF00CCFF);

  // ── Surface / Elevated ────────────────────────────────────
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1A1A);

  // ── Divider / Border ──────────────────────────────────────
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF2A2A2A);

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
  static const double radiusCard = 24;
  static const double radiusInput = 16;
  static const double radiusDialog = 24;
  static const double radiusChip = 999;
}
