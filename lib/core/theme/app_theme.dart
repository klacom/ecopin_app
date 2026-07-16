import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  // ── Light Theme ───────────────────────────────────────────
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryLight,
      onPrimary: Colors.white,
      secondary: AppColors.secondaryLight,
      onSecondary: Colors.white,
      tertiary: AppColors.accent,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      error: AppColors.error,
      onError: Colors.white,
    );

    return _buildTheme(colorScheme);
  }

  // ── Dark Theme ────────────────────────────────────────────
  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      onPrimary: AppColors.backgroundDark,
      secondary: AppColors.secondaryDark,
      onSecondary: AppColors.backgroundDark,
      tertiary: AppColors.accent,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      error: AppColors.error,
      onError: Colors.white,
    );

    return _buildTheme(colorScheme);
  }

  // ── Shared builder ────────────────────────────────────────
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final bool isDark = colorScheme.brightness == Brightness.dark;

    final Color textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final Color scaffoldBg =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final Color dividerColor =
        isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      fontFamily: 'Outfit',

      // ── Text Theme ─────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: AppTypography.display.copyWith(color: textColor),
        headlineLarge: AppTypography.h1.copyWith(color: textColor),
        headlineMedium: AppTypography.h2.copyWith(color: textColor),
        headlineSmall: AppTypography.h3.copyWith(color: textColor),
        titleLarge: AppTypography.h4.copyWith(color: textColor),
        titleMedium: AppTypography.h5.copyWith(color: textColor),
        titleSmall: AppTypography.h6.copyWith(color: textColor),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: textColor),
        bodyMedium: AppTypography.body.copyWith(color: textColor),
        bodySmall: AppTypography.bodySmall.copyWith(color: textColor),
        labelLarge: AppTypography.button.copyWith(color: textColor),
        labelMedium: AppTypography.label.copyWith(color: textColor),
        labelSmall: AppTypography.caption.copyWith(color: textColor),
      ),

      // ── Elevated Button ────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: AppTypography.button.copyWith(color: colorScheme.onPrimary),
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(AppColors.radiusButton)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.spaceLG,
            vertical: AppColors.spaceMD,
          ),
        ),
      ),

      // ── Text Button ────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: AppTypography.button.copyWith(color: colorScheme.primary),
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(AppColors.radiusButton)),
          ),
        ),
      ),

      // ── Outlined Button ────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          textStyle: AppTypography.button.copyWith(color: colorScheme.primary),
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(AppColors.radiusButton)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.spaceLG,
            vertical: AppColors.spaceMD,
          ),
        ),
      ),

      // ── Card ───────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(AppColors.radiusCard)),
        ),
        margin: const EdgeInsets.all(AppColors.spaceSM),
      ),

      // ── Input ──────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppColors.spaceMD,
          vertical: AppColors.spaceMD,
        ),
        border: const OutlineInputBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(AppColors.radiusInput)),
          borderSide: BorderSide(color: AppColors.dividerLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              const BorderRadius.all(Radius.circular(AppColors.radiusInput)),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(AppColors.radiusInput)),
          borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(AppColors.radiusInput)),
          borderSide: BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTypography.label.copyWith(color: textColor),
        hintStyle: AppTypography.body.copyWith(
          color: textColor.withValues(alpha: 0.5),
        ),
      ),

      // ── Dialog ─────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(AppColors.radiusDialog)),
        ),
        titleTextStyle: AppTypography.h3.copyWith(color: textColor),
        contentTextStyle: AppTypography.body.copyWith(color: textColor),
      ),

      // ── Chip ───────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        labelStyle: AppTypography.label.copyWith(color: textColor),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppColors.radiusChip)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppColors.spaceSM,
          vertical: AppColors.spaceXS,
        ),
      ),

      // ── Divider ────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // ── ScaffoldMessenger (snackbar / toast) ───────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.textPrimaryLight,
        contentTextStyle:
            AppTypography.body.copyWith(color: isDark ? Colors.white : Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(AppColors.radiusButton)),
        ),
      ),

      // ── Color scheme extension for status colors ───────────
      extensions: [
        AppStatusColors(
          success: AppColors.success,
          warning: AppColors.warning,
          error: AppColors.error,
          info: AppColors.info,
        ),
      ],
    );
  }
}

// ── Custom extension for status colors ───────────────────────
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  @override
  AppStatusColors copyWith({
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
  }) {
    return AppStatusColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
    );
  }

  @override
  AppStatusColors lerp(AppStatusColors? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}
