import 'package:flutter/material.dart';

import '../../features/weather/domain/weather_condition.dart';
import 'atmos_tokens.dart';

/// The colour treatment for one condition at one time of day: the sky
/// gradient plus the four text roles that sit on it.
///
/// Transcribed from `HOME_PALETTE` in the design prototype, which gives every
/// condition a day *and* a night variant. [isDark] is the switch the rest of
/// the UI reads — it flips glass surfaces, the tab bar tint and the hero's
/// text shadow.
@immutable
class WeatherPalette {
  const WeatherPalette({
    required this.gradient,
    required this.text,
    required this.accentText,
    required this.subText,
    required this.isDark,
    required this.tokens,
  });

  /// The design system this palette was resolved against — the card roles
  /// below read their ramps from it.
  final AtmosTokens tokens;

  /// Three-stop vertical gradient, top to bottom.
  final LinearGradient gradient;

  /// The hero temperature and other primary copy.
  final Color text;

  /// Chrome that sits on the gradient — location name, icon buttons.
  final Color accentText;

  /// "Feels like", axis labels, secondary copy.
  final Color subText;

  /// Whether this sky wants dark glass and light-on-dark chrome.
  final bool isDark;

  Brightness get brightness => isDark ? Brightness.dark : Brightness.light;

  /// The hero temperature at 96px is WCAG "large text", so it holds 3:1
  /// rather than 4.5:1 — which matters, because a mid-tone sky like daytime
  /// rain has no flat colour that reaches 4.5 in either direction.
  Color get heroText => onSkyAt(text, SkyDepth.hero, minimum: 3.0);

  /// The shadow under the hero, tuned to what is behind it.
  ///
  /// A dark sky needs only a soft lift. A mid-tone sky is where light text
  /// goes muddy, so it gets a tighter, stronger shadow to cut the figure out
  /// of the ground. A light sky needs none at all.
  List<Shadow> get heroTextShadow {
    final luminance = skyColorAt(SkyDepth.hero).computeLuminance();
    if (luminance > 0.45) return const [];
    if (luminance > 0.12) {
      return const [
        Shadow(color: Color(0x73000000), offset: Offset(0, 1), blurRadius: 6),
        Shadow(color: Color(0x40000000), offset: Offset(0, 2), blurRadius: 18),
      ];
    }
    return const [
      Shadow(color: Color(0x59000000), offset: Offset(0, 1), blurRadius: 12),
    ];
  }

  // ── Card roles ─────────────────────────────────────────────────────────
  //
  // Home's chips, rows and tiles sit on glass over the sky, so they have to
  // follow it: the light recipe with ink text by day, the dark recipe with
  // light text once the sky goes dark. The prototype only ever drew the light
  // card, which leaves its own text barely legible on the night, rain and
  // storm gradients.

  /// Whether cards over this sky use the dark glass recipe.
  ///
  /// This deliberately does *not* follow [isDark]. The hero sits on the raw
  /// gradient, but a card sits on tinted glass over it, so the two can want
  /// opposite treatments — daytime rain is the case that proves it: the sky
  /// is dark enough for white hero text, yet its mid-tone `neutral-500` under
  /// an 8% white tint leaves white card text at only 2.4:1. Deciding from the
  /// luminance actually behind the glass keeps both readable.
  bool get cardIsDark => gradient.colors[1].computeLuminance() < 0.25;

  /// Primary value text inside a card — the temperature, the metric reading.
  Color get cardText => cardIsDark ? const Color(0xFFF9F4ED) : tokens.text;

  /// Captions inside a card — the hour label, the metric name.
  Color get cardSubText =>
      cardIsDark ? Colors.white.withValues(alpha: 0.72) : tokens.neutral.s700;

  /// The terracotta icon role. The deep ramp step reads on a light card; on a
  /// dark one it disappears, so the light step takes over.
  Color get cardAccent =>
      cardIsDark ? tokens.accentRamp.s300 : tokens.accentRamp.s700;

  /// The sage second voice, same inversion.
  Color get cardAccent2 =>
      cardIsDark ? tokens.accent2Ramp.s300 : tokens.accent2Ramp.s700;

  // ── Text sitting directly on the sky ───────────────────────────────────
  //
  // A vertical gradient changes luminance down the screen, so one text colour
  // cannot serve the whole column: daytime rain runs dark at the top and light
  // at the bottom, which leaves the design's white section labels sitting on
  // a pale background by the time the eye reaches them. These helpers pick a
  // colour for the depth the text actually occupies.

  /// The sky's colour at [t] down the screen, 0 = top, 1 = bottom.
  Color skyColorAt(double t) {
    final stops = gradient.stops ?? const [0.0, 0.5, 1.0];
    final colors = gradient.colors;
    if (t <= stops.first) return colors.first;
    if (t >= stops.last) return colors.last;

    for (var i = 0; i < stops.length - 1; i++) {
      if (t >= stops[i] && t <= stops[i + 1]) {
        final span = stops[i + 1] - stops[i];
        final local = span == 0 ? 0.0 : (t - stops[i]) / span;
        return Color.lerp(colors[i], colors[i + 1], local)!;
      }
    }
    return colors.last;
  }

  /// Keeps [preferred] — the colour the design chose — when it still reads at
  /// depth [t], and otherwise falls back to whichever of ink or off-white has
  /// more contrast there.
  ///
  /// [minimum] is the WCAG ratio to hold: 4.5 for body text, 3.0 for large
  /// text, icons and interface chrome.
  Color onSkyAt(Color preferred, double t, {double minimum = 4.5}) {
    final background = skyColorAt(t);
    // The design's muted roles are translucent white, and luminance ignores
    // alpha — measuring them unflattened would score them as solid white and
    // wave through text that is actually washed out.
    final effective = Color.alphaBlend(preferred, background);
    if (contrastRatio(effective, background) >= minimum) return preferred;

    const paper = Color(0xFFF9F4ED);
    return contrastRatio(paper, background) >=
            contrastRatio(tokens.text, background)
        ? paper
        : tokens.text;
  }

  /// The muted role — "feels like", section kickers — at depth [t].
  Color onSkyMutedAt(double t) {
    final resolved = onSkyAt(subText, t, minimum: 3.0);
    if (resolved == subText) return resolved;

    // A flipped colour is muted back down so it still reads as secondary —
    // but only as far as it can go while holding 3:1. On a mid-tone sky the
    // headroom runs out, and legibility wins over hierarchy.
    final background = skyColorAt(t);
    const muted = 0.78;
    final candidate = resolved.withValues(alpha: muted);
    final flattened = Color.alphaBlend(candidate, background);
    return contrastRatio(flattened, background) >= 3.0 ? candidate : resolved;
  }

  /// WCAG 2.x contrast ratio. Both colours are treated as opaque.
  static double contrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final hi = l1 > l2 ? l1 : l2;
    final lo = l1 > l2 ? l2 : l1;
    return (hi + 0.05) / (lo + 0.05);
  }

  static LinearGradient _sky(
    Color top,
    Color mid,
    Color bottom,
    double midStop,
  ) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, mid, bottom],
      stops: [0, midStop, 1],
    );
  }

  /// Resolves the palette for a condition at a time of day.
  ///
  /// [tokens] supplies the Organic ramps the CSS gradients referenced through
  /// `var(--color-*)`.
  static WeatherPalette resolve(
    AtmosTokens t,
    WeatherCondition condition, {
    required bool isNight,
  }) {
    const white = Color(0xFFFFFFFF);
    final onDark = white.withValues(alpha: 0.78);
    final onDarkDim = white.withValues(alpha: 0.75);
    final onDarkDimmest = white.withValues(alpha: 0.70);

    return switch ((condition, isNight)) {
      (WeatherCondition.clear, false) => WeatherPalette(
        gradient: _sky(t.accentRamp.s200, t.bg, t.accentRamp.s100, 0.45),
        text: t.text,
        accentText: t.accentRamp.s800,
        subText: t.neutral.s700,
        isDark: false,
        tokens: t,
      ),
      (WeatherCondition.clear, true) => WeatherPalette(
        gradient: _sky(t.neutral.s900, t.neutral.s900, t.accentRamp.s900, 0.55),
        text: white,
        accentText: white,
        subText: onDark,
        isDark: true,
        tokens: t,
      ),
      (WeatherCondition.cloudy, false) => WeatherPalette(
        gradient: _sky(t.neutral.s500, t.neutral.s300, t.bg, 0.55),
        text: t.neutral.s900,
        accentText: t.neutral.s800,
        subText: t.neutral.s700,
        isDark: false,
        tokens: t,
      ),
      (WeatherCondition.cloudy, true) => WeatherPalette(
        gradient: _sky(t.neutral.s900, t.neutral.s800, t.neutral.s700, 0.55),
        text: white,
        accentText: white,
        subText: onDark,
        isDark: true,
        tokens: t,
      ),
      (WeatherCondition.fog, false) => WeatherPalette(
        gradient: _sky(t.neutral.s400, t.neutral.s200, t.neutral.s100, 0.55),
        text: t.neutral.s800,
        accentText: t.neutral.s700,
        subText: t.neutral.s600,
        isDark: false,
        tokens: t,
      ),
      (WeatherCondition.fog, true) => WeatherPalette(
        gradient: _sky(t.neutral.s800, t.neutral.s700, t.neutral.s600, 0.55),
        text: white,
        accentText: white,
        subText: onDarkDim,
        isDark: true,
        tokens: t,
      ),
      (WeatherCondition.drizzle, false) => WeatherPalette(
        gradient: _sky(
          t.neutral.s500,
          t.neutral.s300,
          t.accent2Ramp.s100,
          0.55,
        ),
        text: t.neutral.s900,
        accentText: t.neutral.s800,
        subText: t.neutral.s700,
        isDark: false,
        tokens: t,
      ),
      (WeatherCondition.drizzle, true) => WeatherPalette(
        gradient: _sky(
          t.neutral.s900,
          t.neutral.s800,
          t.accent2Ramp.s900,
          0.55,
        ),
        text: white,
        accentText: white,
        subText: onDark,
        isDark: true,
        tokens: t,
      ),
      // Rain reads as a dark sky even in daylight.
      (WeatherCondition.rain, false) => WeatherPalette(
        gradient: _sky(t.neutral.s700, t.neutral.s500, t.neutral.s300, 0.55),
        text: t.neutral.s100,
        accentText: t.neutral.s100,
        subText: onDarkDim,
        isDark: true,
        tokens: t,
      ),
      (WeatherCondition.rain, true) => WeatherPalette(
        gradient: _sky(t.neutral.s900, t.neutral.s900, t.neutral.s800, 0.55),
        text: white,
        accentText: white,
        subText: onDarkDim,
        isDark: true,
        tokens: t,
      ),
      (WeatherCondition.snow, false) => WeatherPalette(
        gradient: _sky(t.accent2Ramp.s100, t.bg, white, 0.55),
        text: t.text,
        accentText: t.accent2Ramp.s800,
        subText: t.neutral.s700,
        isDark: false,
        tokens: t,
      ),
      (WeatherCondition.snow, true) => WeatherPalette(
        gradient: _sky(
          t.neutral.s900,
          t.accent2Ramp.s900,
          t.accent2Ramp.s800,
          0.60,
        ),
        text: white,
        accentText: white,
        subText: onDark,
        isDark: true,
        tokens: t,
      ),
      (WeatherCondition.storm, false) => WeatherPalette(
        gradient: _sky(t.neutral.s800, t.accentRamp.s900, t.neutral.s600, 0.55),
        text: t.neutral.s100,
        accentText: t.neutral.s100,
        subText: onDarkDimmest,
        isDark: true,
        tokens: t,
      ),
      (WeatherCondition.storm, true) => WeatherPalette(
        gradient: _sky(t.neutral.s900, t.neutral.s900, t.accentRamp.s900, 0.55),
        text: white,
        accentText: white,
        subText: onDarkDim,
        isDark: true,
        tokens: t,
      ),
    };
  }
}

/// One frame of the onboarding mood carousel.
///
/// Transcribed from `OB_MOODS` — five moods on a 3.5s cycle. These are their
/// own palettes because the onboarding gradients differ from Home's (softer
/// stops, and the ambient layers are drawn larger).
@immutable
class OnboardingMood {
  const OnboardingMood({
    required this.condition,
    required this.isNight,
    required this.gradient,
    required this.text,
    required this.darkCard,
  });

  final WeatherCondition condition;
  final bool isNight;
  final LinearGradient gradient;
  final Color text;

  /// Whether the action card uses the dark glass recipe.
  final bool darkCard;

  static List<OnboardingMood> all(AtmosTokens t) => [
    OnboardingMood(
      condition: WeatherCondition.clear,
      isNight: false,
      gradient: WeatherPalette._sky(
        t.accentRamp.s200,
        t.bg,
        t.accentRamp.s100,
        0.55,
      ),
      text: t.text,
      darkCard: false,
    ),
    OnboardingMood(
      condition: WeatherCondition.cloudy,
      isNight: false,
      gradient: WeatherPalette._sky(t.neutral.s400, t.neutral.s200, t.bg, 0.55),
      text: t.neutral.s900,
      darkCard: false,
    ),
    OnboardingMood(
      condition: WeatherCondition.rain,
      isNight: false,
      gradient: WeatherPalette._sky(
        t.neutral.s700,
        t.neutral.s500,
        t.neutral.s300,
        0.55,
      ),
      text: const Color(0xFFFFFFFF),
      darkCard: true,
    ),
    OnboardingMood(
      condition: WeatherCondition.storm,
      isNight: false,
      gradient: WeatherPalette._sky(
        t.neutral.s800,
        t.accentRamp.s900,
        t.neutral.s600,
        0.55,
      ),
      text: const Color(0xFFFFFFFF),
      darkCard: true,
    ),
    OnboardingMood(
      condition: WeatherCondition.clear,
      isNight: true,
      gradient: WeatherPalette._sky(
        t.neutral.s900,
        t.accentRamp.s900,
        t.accentRamp.s800,
        0.70,
      ),
      text: t.neutral.s100,
      darkCard: true,
    ),
  ];
}

/// Roughly how far down the screen each piece of sky-level text sits, as a
/// fraction of the viewport. The sky gradient changes luminance with depth, so
/// a colour is only readable relative to a position — these keep the call
/// sites honest about which one they mean.
abstract final class SkyDepth {
  static const double locationBar = 0.10;
  static const double refreshHint = 0.18;
  static const double hero = 0.30;
  static const double feelsLike = 0.38;
  static const double hourlyLabel = 0.44;
  static const double dailyLabel = 0.64;
}
