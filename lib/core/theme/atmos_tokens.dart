import 'package:flutter/material.dart';

/// The **Organic** design system, ported verbatim from the Claude Design
/// project's `_ds/organic-…/styles.css`.
///
/// That stylesheet is the source of truth for the look; this class is its
/// typed mirror. Nothing else in the app hard-codes a hex, a radius or a
/// spacing value — read them from `Theme.of(context).tokens` instead.
@immutable
class AtmosTokens extends ThemeExtension<AtmosTokens> {
  const AtmosTokens({
    required this.bg,
    required this.surface,
    required this.text,
    required this.accent,
    required this.accent2,
    required this.divider,
    required this.neutral,
    required this.accentRamp,
    required this.accent2Ramp,
  });

  /// The one light theme the design system defines.
  factory AtmosTokens.organic() => const AtmosTokens(
    bg: Color(0xFFF5EAD8),
    surface: Color(0xFFEBDDC5),
    text: Color(0xFF201E1D),
    accent: Color(0xFFC67139),
    accent2: Color(0xFF7A8A5E),
    // color-mix(in srgb, #201e1d 16%, transparent)
    divider: Color(0x29201E1D),
    neutral: _TonalRamp(
      s100: Color(0xFFF9F4ED),
      s200: Color(0xFFEEE7DB),
      s300: Color(0xFFDCD3C4),
      s400: Color(0xFFC0B6A5),
      s500: Color(0xFFA19786),
      s600: Color(0xFF82796A),
      s700: Color(0xFF645C50),
      s800: Color(0xFF474238),
      s900: Color(0xFF2E2B25),
    ),
    accentRamp: _TonalRamp(
      s100: Color(0xFFFFF2EB),
      s200: Color(0xFFFFE1D0),
      s300: Color(0xFFFFC6A5),
      s400: Color(0xFFF6A06B),
      s500: Color(0xFFD67F48),
      s600: Color(0xFFB2622D),
      s700: Color(0xFF8C491A),
      s800: Color(0xFF643312),
      s900: Color(0xFF402310),
    ),
    accent2Ramp: _TonalRamp(
      s100: Color(0xFFF0FAE1),
      s200: Color(0xFFE1EECC),
      s300: Color(0xFFCCDBB2),
      s400: Color(0xFFAEBF92),
      s500: Color(0xFF8FA073),
      s600: Color(0xFF728157),
      s700: Color(0xFF56633F),
      s800: Color(0xFF3D472B),
      s900: Color(0xFF272E1B),
    ),
  );

  final Color bg;
  final Color surface;
  final Color text;
  final Color accent;
  final Color accent2;
  final Color divider;

  /// 100–900 ramps generated in OKLCH on one shared lightness scale, so the
  /// same step of any role matches the others in visual value.
  final TonalRamp neutral;
  final TonalRamp accentRamp;
  final TonalRamp accent2Ramp;

  // ── Type ──────────────────────────────────────────────────────────────
  static const String fontHeading = 'Caprasimo';
  static const String fontBody = 'Figtree';
  static const FontWeight headingWeight = FontWeight.w400;

  // ── Spacing — density 1.10× is already baked in ───────────────────────
  static const double space1 = 4.4;
  static const double space2 = 8.8;
  static const double space3 = 13.2;
  static const double space4 = 17.6;
  static const double space6 = 26.4;
  static const double space8 = 35.2;

  // ── Radii — over-rounded; small controls go pill ──────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 16;
  static const double radiusLg = 28;
  static const double radiusPill = 999;

  /// `.card` / `.dialog` grow past `--radius-lg` in the rounded frame.
  static const double radiusCard = radiusLg * 1.15;

  // ── Elevation — soft ink-tinted shadows tuned to the warm ground ──────
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x242E2B25), // #2e2b25 at 14%
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x292E2B25), // 16%
      offset: Offset(0, 3),
      blurRadius: 10,
    ),
  ];
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x382E2B25), // 22%
      offset: Offset(0, 12),
      blurRadius: 32,
    ),
  ];

  /// `.text-muted` — `color-mix(in srgb, var(--color-text) 55%, transparent)`.
  Color get textMuted => text.withValues(alpha: 0.55);

  @override
  AtmosTokens copyWith({
    Color? bg,
    Color? surface,
    Color? text,
    Color? accent,
    Color? accent2,
    Color? divider,
    TonalRamp? neutral,
    TonalRamp? accentRamp,
    TonalRamp? accent2Ramp,
  }) {
    return AtmosTokens(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      accent: accent ?? this.accent,
      accent2: accent2 ?? this.accent2,
      divider: divider ?? this.divider,
      neutral: neutral ?? this.neutral,
      accentRamp: accentRamp ?? this.accentRamp,
      accent2Ramp: accent2Ramp ?? this.accent2Ramp,
    );
  }

  @override
  AtmosTokens lerp(covariant AtmosTokens? other, double t) {
    if (other == null) return this;
    return AtmosTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accent2: Color.lerp(accent2, other.accent2, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      neutral: neutral.lerp(other.neutral, t),
      accentRamp: accentRamp.lerp(other.accentRamp, t),
      accent2Ramp: accent2Ramp.lerp(other.accent2Ramp, t),
    );
  }
}

/// A 100–900 tonal ramp. Light steps (100–300) are tinted fills, hovers and
/// subtle borders; 500 is the role's base; dark steps (700–900) carry text on
/// tinted fills and pressed states.
abstract class TonalRamp {
  Color get s100;
  Color get s200;
  Color get s300;
  Color get s400;
  Color get s500;
  Color get s600;
  Color get s700;
  Color get s800;
  Color get s900;

  /// Index the ramp the way CSS does: `ramp[700]`.
  Color operator [](int step);

  TonalRamp lerp(TonalRamp other, double t);
}

class _TonalRamp implements TonalRamp {
  const _TonalRamp({
    required this.s100,
    required this.s200,
    required this.s300,
    required this.s400,
    required this.s500,
    required this.s600,
    required this.s700,
    required this.s800,
    required this.s900,
  });

  @override
  final Color s100;
  @override
  final Color s200;
  @override
  final Color s300;
  @override
  final Color s400;
  @override
  final Color s500;
  @override
  final Color s600;
  @override
  final Color s700;
  @override
  final Color s800;
  @override
  final Color s900;

  @override
  Color operator [](int step) => switch (step) {
    100 => s100,
    200 => s200,
    300 => s300,
    400 => s400,
    500 => s500,
    600 => s600,
    700 => s700,
    800 => s800,
    900 => s900,
    _ => throw ArgumentError.value(step, 'step', 'not a 100–900 ramp step'),
  };

  @override
  TonalRamp lerp(TonalRamp other, double t) => _TonalRamp(
    s100: Color.lerp(s100, other.s100, t)!,
    s200: Color.lerp(s200, other.s200, t)!,
    s300: Color.lerp(s300, other.s300, t)!,
    s400: Color.lerp(s400, other.s400, t)!,
    s500: Color.lerp(s500, other.s500, t)!,
    s600: Color.lerp(s600, other.s600, t)!,
    s700: Color.lerp(s700, other.s700, t)!,
    s800: Color.lerp(s800, other.s800, t)!,
    s900: Color.lerp(s900, other.s900, t)!,
  );
}

extension AtmosThemeX on ThemeData {
  /// Every widget reaches the design system through this.
  ///
  /// Falls back to the stock Organic tokens when the extension is missing, so
  /// a widget rendered under a bare `MaterialApp` — a test, a preview, a
  /// screenshot harness — still draws in the right palette instead of
  /// crashing.
  AtmosTokens get tokens => extension<AtmosTokens>() ?? AtmosTokens.organic();
}

extension AtmosContextX on BuildContext {
  AtmosTokens get tokens => Theme.of(this).tokens;
}
