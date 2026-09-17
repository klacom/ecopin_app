import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  // ── Display ───────────────────────────────────────────────
  static const TextStyle display = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 48,
    height: 1.1,
    letterSpacing: -1.5,
  );

  // ── Headings ──────────────────────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 40,
    height: 1.1,
    letterSpacing: -1.0,
  );

  static const TextStyle h2 = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static const TextStyle h3 = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 28,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static const TextStyle h4 = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 1.2,
  );

  static const TextStyle h5 = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1.3,
  );

  static const TextStyle h6 = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 1.3,
  );

  // ── Body ──────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 18,
    height: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.4,
  );

  // ── Caption ───────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.3,
    letterSpacing: 0.2,
  );

  // ── Label ─────────────────────────────────────────────────
  static const TextStyle label = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.3,
    letterSpacing: 0.1,
  );

  // ── Button ────────────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.25,
    letterSpacing: 0.3,
  );
}
