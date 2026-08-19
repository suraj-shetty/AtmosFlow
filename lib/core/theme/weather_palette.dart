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

  // ── Card roles ─────────────────────────────────────────────────────────
  //
  // The design already switches its Day Detail panels on `hp.dark` — dark
  // glass, light copy — but leaves Home's chips, rows and tiles hardcoded to
  // the light recipe with ink text. Over a night or storm sky that is close
  // to unreadable, so Home follows the rule the design applies one screen
  // over rather than the literal markup.

  /// Whether a *card* wants the dark glass recipe.
  ///
  /// Not the same question as [isDark]. That flag describes the top of the
  /// screen, where the hero and the header sit, and a daytime rain sky is
  /// genuinely dark there — but it ramps from neutral-700 down to
  /// neutral-300, so by the time the eye reaches the cards the sky is light
  /// again. Cards ask about the gradient they actually sit on instead.
  bool get cardIsDark => gradient.colors[1].computeLuminance() < 0.25;

  /// `--color-text` inside a card: the temperature, the metric reading.
  Color get cardText => cardIsDark ? const Color(0xFFF9F4ED) : tokens.text;

  /// `--color-neutral-600/700`: hour labels, metric captions, the low temp.
  ///
  /// The design mixes 600 and 700 here; 700 throughout, because 600 falls
  /// under 3:1 on the grey glass a rainy daytime sky produces.
  Color get cardSubText =>
      cardIsDark ? Colors.white.withValues(alpha: 0.72) : tokens.neutral.s700;

  /// `--color-neutral-500`: the chevron at the end of a daily row.
  Color get cardFaintText =>
      cardIsDark ? Colors.white.withValues(alpha: 0.5) : tokens.neutral.s500;

  /// The terracotta icon role. The deep ramp step reads on a light card and
  /// vanishes on a dark one, so the light step takes over.
  Color get cardAccent =>
      cardIsDark ? tokens.accentRamp.s300 : tokens.accentRamp.s700;

  /// The sage second voice — the metric icons and the precipitation line.
  Color get cardAccent2 =>
      cardIsDark ? tokens.accent2Ramp.s300 : tokens.accent2Ramp.s700;

  /// The uppercase kickers above each list. They sit on bare gradient but
  /// well below the hero, so — unlike [subText] — they answer to the sky
  /// down there. Neutral-800 rather than the design's 700: a daytime rain sky
  /// is still mid-grey at that depth, where 700 disappears.
  Color get kickerText =>
      cardIsDark ? Colors.white.withValues(alpha: 0.8) : tokens.neutral.s800;

  /// `homeTextShadow` — the design lifts the hero off a dark sky with a
  /// single soft shadow, and leaves a light sky alone.
  List<Shadow> get heroTextShadow => isDark
      ? const [
          Shadow(color: Color(0x59000000), offset: Offset(0, 1), blurRadius: 12),
        ]
      : const [];

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
