import 'package:flutter/material.dart';

import 'atmos_tokens.dart';

/// Builds `ThemeData` from the Organic tokens.
///
/// The design system defines a single warm light theme; the app's "dark"
/// theme is the same system with the ground swapped for `neutral-900`, which
/// is exactly what the Settings screen does (`accent-800 → neutral-900`).
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final tokens = AtmosTokens.organic();
    final isDark = brightness == Brightness.dark;

    final ground = isDark ? tokens.neutral.s900 : tokens.bg;
    final onGround = isDark ? tokens.neutral.s100 : tokens.text;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: tokens.accent,
      onPrimary: tokens.bg,
      secondary: tokens.accent2,
      onSecondary: tokens.bg,
      surface: isDark ? tokens.neutral.s800 : tokens.surface,
      onSurface: onGround,
      error: tokens.accentRamp.s700,
      onError: tokens.neutral.s100,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: ground,
      fontFamily: AtmosTokens.fontBody,
      splashFactory: InkSparkle.splashFactory,
      extensions: [tokens],
      textTheme: _textTheme(onGround),
      // The design system never leaves a default focus ring: keyboard focus is
      // a 2px accent outline.
      focusColor: tokens.accent.withValues(alpha: 0.12),
      dividerTheme: DividerThemeData(
        color: tokens.divider,
        thickness: 1,
        space: 1,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: tokens.accent,
        selectionColor: tokens.accent.withValues(alpha: 0.3),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: tokens.bg,
          textStyle: const TextStyle(
            fontFamily: AtmosTokens.fontHeading,
            fontWeight: AtmosTokens.headingWeight,
            fontSize: 15,
            height: 1.2,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.accent,
          textStyle: const TextStyle(
            fontFamily: AtmosTokens.fontHeading,
            fontWeight: AtmosTokens.headingWeight,
            fontSize: 13,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// The CSS type scale: Caprasimo headings (h1 42 → h6 13) over Figtree body
  /// at 15px/1.55.
  static TextTheme _textTheme(Color onGround) {
    TextStyle heading(double size) => TextStyle(
      fontFamily: AtmosTokens.fontHeading,
      fontWeight: AtmosTokens.headingWeight,
      fontSize: size,
      height: 1.12,
      letterSpacing: -0.015 * size,
      color: onGround,
    );
    TextStyle body(double size, {FontWeight weight = FontWeight.w400}) =>
        TextStyle(
          fontFamily: AtmosTokens.fontBody,
          fontWeight: weight,
          fontSize: size,
          height: 1.55,
          color: onGround,
        );

    return TextTheme(
      displayLarge: heading(42),
      displayMedium: heading(32),
      displaySmall: heading(25),
      headlineMedium: heading(20),
      headlineSmall: heading(16),
      titleLarge: heading(22),
      titleMedium: body(15, weight: FontWeight.w600),
      titleSmall: body(14, weight: FontWeight.w600),
      bodyLarge: body(15),
      bodyMedium: body(14),
      bodySmall: body(13),
      // h6 — the uppercase section kicker used above every list.
      labelLarge: TextStyle(
        fontFamily: AtmosTokens.fontBody,
        fontSize: 11,
        height: 1.4,
        letterSpacing: 0.08 * 11,
        color: onGround,
      ),
      labelMedium: body(12),
      labelSmall: body(11),
    );
  }
}
