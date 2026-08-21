import 'package:flutter/animation.dart';

/// Every duration and curve in the app, transcribed from the design's CSS
/// keyframes and transitions. Keeping them here means a timing change is one
/// edit, and tests can pump exact frames.
abstract final class Motion {
  // ── Screen + chrome ───────────────────────────────────────────────────
  /// `transition:opacity .4s ease, transform .4s cubic-bezier(.22,1,.36,1)`
  static const Duration screenTransition = Duration(milliseconds: 400);
  static const Curve screenTransitionCurve = Cubic(0.22, 1, 0.36, 1);

  /// Search and Settings are presented like an iOS full-screen cover: up
  /// from the bottom edge, decelerating in and accelerating out. The design
  /// leaves route-level motion unspecified, so these follow the platform.
  static const Duration modalPresent = Duration(milliseconds: 420);
  static const Duration modalDismiss = Duration(milliseconds: 330);
  static const Curve modalPresentCurve = Cubic(0.22, 1, 0.36, 1);
  static const Curve modalDismissCurve = Curves.easeInCubic;

  /// The design's overshoot spring, `cubic-bezier(.34,1.56,.64,1)`. Named for
  /// the prototype's tab icon; this app presents Search and Settings modally
  /// instead, so what still springs on it is the refresh puck and the hourly
  /// chip.
  static const Curve tabBounceCurve = Cubic(0.34, 1.56, 0.64, 1);

  // ── Hourly strip ──────────────────────────────────────────────────────
  /// Tapping an hour chip opens it. The design's `.35s` is quick enough that
  /// the growth reads as a jump rather than a move, so the expand runs long
  /// enough to be followed — every property on the chip (height, corner
  /// radius, scale, fill, shadow) is driven from this one duration so they
  /// arrive together.
  static const Duration hourExpand = Duration(milliseconds: 520);
  static const Duration hourCollapse = Duration(milliseconds: 440);

  /// Opening springs past its resting size; closing just eases back, because
  /// an overshoot on the way out reads as a bounce off the neighbouring chip.
  static const Curve hourExpandCurve = tabBounceCurve;
  static const Curve hourCollapseCurve = Cubic(0.4, 0, 0.2, 1);

  /// The chip's corners open out with it — `--radius-lg` closed,
  /// `--radius-card` at full stretch.
  static const double hourRadiusClosed = 28; // AtmosTokens.radiusLg
  static const double hourRadiusOpen = 28 * 1.15; // AtmosTokens.radiusCard

  // ── Home ──────────────────────────────────────────────────────────────
  /// `@keyframes fadeSlideUp` — 18px rise, used by the metric grid.
  static const Duration fadeSlideUp = Duration(milliseconds: 500);
  static const double fadeSlideUpOffset = 18;
  static const Duration metricStagger = Duration(milliseconds: 60);

  /// The refresh puck: it springs down into view, and its icon plays one
  /// `sunSpinBounce` turn for as long as the prototype pretends to refresh.
  static const Duration refreshMinimum = Duration(milliseconds: 1100);
  static const Duration refreshSpin = Duration(milliseconds: 1100);
  static const Duration refreshPuckSlide = Duration(milliseconds: 500);
  static const Duration refreshPuckFade = Duration(milliseconds: 350);

  /// Where the puck waits when it is not showing: 46px up, at 60% scale.
  static const double refreshPuckHiddenLift = 46;
  static const double refreshPuckHiddenScale = 0.6;

  /// Parallax multipliers applied to the scroll offset.
  static const double parallaxFast = -0.25; // sun
  static const double parallaxSlow = -0.12; // clouds and other slow layers

  // ── Day detail ────────────────────────────────────────────────────────
  /// The temperature line draws itself on.
  static const Duration graphDraw = Duration(milliseconds: 1100);
  static const Curve graphDrawCurve = Cubic(0.22, 1, 0.36, 1);

  /// The sun sweeps out to wherever the day has actually got to, on `1-(1-t)³`
  /// — the design's fixture happened to sit at 58%.
  static const Duration arcSweep = Duration(milliseconds: 1100);
  static const Curve arcSweepCurve = Curves.easeOutCubic;

  /// Both detail charts wait for the screen transition before starting.
  static const Duration detailChartDelay = Duration(milliseconds: 250);

  // ── Settings ──────────────────────────────────────────────────────────
  /// `@keyframes flipY` on the demo temperature chip when the unit changes.
  static const Duration unitFlip = Duration(milliseconds: 500);

  // ── Launch ────────────────────────────────────────────────────────────
  /// The brand design's launch timeline, as absolute marks from Flutter's
  /// first frame: 0ms the static OS image, 180ms the sky starts moving, 260ms
  /// the wordmark rises, 600ms it is in place and held, 800ms the crossfade
  /// into the live condition begins, and under 1.2s the whole thing is over.
  ///
  /// The design's own demo page plays the rise over .7s, which would still be
  /// running when the crossfade starts; the timeline it ships beside it is the
  /// one that adds up, so the rise takes the 340ms between its two marks.
  static const Duration splashSkyIn = Duration(milliseconds: 180);
  static const Duration splashRiseStart = Duration(milliseconds: 260);
  static const Duration splashRiseEnd = Duration(milliseconds: 600);
  static const Duration splashDwell = Duration(milliseconds: 800);
  static const Duration splashHandoff = Duration(milliseconds: 400);

  /// One turn of the splash sky's idle motion — the sun breathing, the band
  /// sliding. The design gives each element its own period; they share one
  /// here because nothing on this screen lives long enough to drift apart.
  static const Duration splashIdle = Duration(milliseconds: 3400);

  /// "The hairline progress bar appears at 1.5s. Never a spinner — the sky is
  /// the loading state."
  static const Duration splashPatience = Duration(milliseconds: 1500);

  // ── Onboarding ────────────────────────────────────────────────────────
  /// The mood carousel advances every 3.5s, cross-fading over 1.2s.
  static const Duration moodDwell = Duration(milliseconds: 3500);
  static const Duration moodCrossFade = Duration(milliseconds: 1200);

  // ── Ambient sky ───────────────────────────────────────────────────────
  static const Duration sunRaySpin = Duration(seconds: 120);
  static const Duration sunGlowPulse = Duration(milliseconds: 4500);
  static const Duration lightningCycle = Duration(milliseconds: 3200);
}
