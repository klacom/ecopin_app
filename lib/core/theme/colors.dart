import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand: Primary Green ──────────────────────────────────
  static const Color primaryLight = Color(0xFF457113);
  static const Color primaryDark = Color(0xFFC0EC8E);

  // ── Brand: Secondary Green ────────────────────────────────
  static const Color secondaryLight = Color(0xFF699834);
  static const Color secondaryDark = Color(0xFF9CCB67);

  // ── Brand: Accent Green ───────────────────────────────────
  static const Color accent = Color(0xFF85D22D);

  // ── Neutrals ──────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF0D1207);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);

  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF000000);

  // ── Status ────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF0288D1);

  // ── Surface / Elevated ────────────────────────────────────
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color surfaceDark = Color(0xFF121212);

  // ── Divider / Border ──────────────────────────────────────
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF2C2C2C);

  // ── Shadows ───────────────────────────────────────────────
  static const Color shadowCard = Color(0x14000000);
  static const Color shadowFloating = Color(0x29000000);
  static const Color shadowDialog = Color(0x33000000);

  // ── Spacing tokens (8-point grid) ────────────────────────
  static const double spaceXS = 4;
  static const double spaceSM = 8;
  static const double spaceMD = 16;
  static const double spaceLG = 24;
  static const double spaceXL = 32;
  static const double spaceXXL = 48;
  static const double spaceXXXL = 64;

  // ── Border Radius tokens ──────────────────────────────────
  static const double radiusButton = 12;
  static const double radiusCard = 16;
  static const double radiusInput = 12;
  static const double radiusDialog = 20;
  static const double radiusChip = 999;
}
