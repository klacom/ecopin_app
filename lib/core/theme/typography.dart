import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  // ── Display ───────────────────────────────────────────────
  static const TextStyle display = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 48,
    height: 48 / 48,
    letterSpacing: -1.5,
  );

  // ── Headings ──────────────────────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 40,
    height: 40 / 40,
    letterSpacing: -1.0,
  );

  static const TextStyle h2 = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 32,
    height: 32 / 32,
    letterSpacing: -0.5,
  );

  static const TextStyle h3 = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 28,
    height: 28 / 28,
    letterSpacing: -0.5,
  );

  static const TextStyle h4 = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 24,
    height: 24 / 24,
  );

  static const TextStyle h5 = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 20,
    height: 24 / 20,
  );

  static const TextStyle h6 = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 18,
    height: 20 / 18,
  );

  // ── Body ──────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
  );

  static const TextStyle body = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 16,
    height: 20 / 16,
  );

  static const TextStyle bodySmall = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 18 / 14,
  );

  // ── Caption ───────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontFamily: 'monospace',
    fontWeight: FontWeight.w700,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 1.0,
  );

  // ── Label ─────────────────────────────────────────────────
  static const TextStyle label = TextStyle(
    fontFamily: 'monospace',
    fontWeight: FontWeight.w700,
    fontSize: 14,
    height: 18 / 14,
    letterSpacing: 1.0,
  );

  // ── Button ────────────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 16,
    height: 20 / 16,
    letterSpacing: 0.5,
  );
}
