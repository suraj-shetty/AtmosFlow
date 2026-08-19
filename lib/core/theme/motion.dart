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

  /// The design fades the outgoing screen for 160ms before swapping.
  static const Duration screenSwapDelay = Duration(milliseconds: 160);

  /// Tab icon pops to 1.22× on tap, then settles.
  static const Duration tabBounce = Duration(milliseconds: 300);
  static const Duration tabBounceHold = Duration(milliseconds: 400);
  static const Curve tabBounceCurve = Cubic(0.34, 1.56, 0.64, 1);
  static const double tabBounceScale = 1.22;

  // ── Home ──────────────────────────────────────────────────────────────
  /// `@keyframes fadeSlideUp` — 18px rise, used by the metric grid.
  static const Duration fadeSlideUp = Duration(milliseconds: 500);
  static const double fadeSlideUpOffset = 18;
  static const Duration metricStagger = Duration(milliseconds: 60);

  /// `bounceIcon` on the pull-to-refresh affordance, and how long the
  /// prototype pretends to refresh for.
  static const Duration refreshBounce = Duration(milliseconds: 800);
  static const Duration refreshMinimum = Duration(milliseconds: 900);

  /// Parallax multipliers applied to the scroll offset.
  static const double parallaxFast = -0.25; // sun
  static const double parallaxSlow = -0.12; // clouds and other slow layers

  // ── Day detail ────────────────────────────────────────────────────────
  /// The temperature line draws itself on.
  static const Duration graphDraw = Duration(milliseconds: 1100);
  static const Curve graphDrawCurve = Cubic(0.22, 1, 0.36, 1);
  static const Duration graphAreaFade = Duration(milliseconds: 1000);
  static const Duration graphAreaDelay = Duration(milliseconds: 300);

  /// The sun travels to 58% of its arc on `1-(1-t)³`.
  static const Duration arcSweep = Duration(milliseconds: 1100);
  static const Curve arcSweepCurve = Curves.easeOutCubic;
  static const double arcTarget = 0.58;

  /// Both detail charts wait for the screen transition before starting.
  static const Duration detailChartDelay = Duration(milliseconds: 250);

  // ── Settings ──────────────────────────────────────────────────────────
  /// `@keyframes flipY` on the demo temperature chip when the unit changes.
  static const Duration unitFlip = Duration(milliseconds: 500);

  // ── Onboarding ────────────────────────────────────────────────────────
  /// The mood carousel advances every 3.5s, cross-fading over 1.2s.
  static const Duration moodDwell = Duration(milliseconds: 3500);
  static const Duration moodCrossFade = Duration(milliseconds: 1200);

  /// "Enable Location" shows "Locating…" for this long before Home.
  static const Duration locating = Duration(milliseconds: 900);

  // ── Ambient sky ───────────────────────────────────────────────────────
  /// One full left→right traverse; individual clouds pick their own period.
  static const Duration cloudDriftSlowest = Duration(seconds: 42);
  static const Duration sunRaySpin = Duration(seconds: 120);
  static const Duration sunGlowPulse = Duration(milliseconds: 4500);
  static const Duration lightningCycle = Duration(milliseconds: 3200);
  static const Duration twinkleBase = Duration(milliseconds: 3500);
}
