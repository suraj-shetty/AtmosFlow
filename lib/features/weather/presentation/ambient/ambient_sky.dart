import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/motion.dart';
import '../../domain/weather_condition.dart';
import 'drifting_shapes.dart';
import 'particle_layer.dart';
import 'storm_layer.dart';
import 'sun_layer.dart';

/// Everything moving behind the content: clouds, sun, rain, snow, fog,
/// lightning and stars, composed per condition exactly as `buildHomeAmbient`
/// does in the design prototype.
///
/// The whole thing sits in a [RepaintBoundary] and listens to [scrollOffset]
/// directly, so scrolling Home repaints the sky without rebuilding the
/// content above it.
class AmbientSky extends StatelessWidget {
  const AmbientSky({
    super.key,
    required this.condition,
    required this.isNight,
    this.scrollOffset,
    this.enabled = true,
  });

  final WeatherCondition condition;
  final bool isNight;

  /// Home's scroll position. Null on screens that don't scroll the sky.
  final ValueListenable<double>? scrollOffset;

  /// False holds the sky still — for goldens, and for users who have asked
  /// the OS to reduce motion.
  ///
  /// Still, not absent: Reduce Motion asks for less movement, not for a bare
  /// gradient, and the sun, moon, stars and clouds are as much a part of
  /// reading the weather here as the temperature is.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final offset = scrollOffset;
    final layers = offset == null
        ? _Layers(condition: condition, isNight: isNight)
        : ValueListenableBuilder<double>(
            valueListenable: offset,
            builder: (context, value, _) =>
                _Layers(condition: condition, isNight: isNight, scroll: value),
          );

    return RepaintBoundary(
      // Every layer drives itself from its own controller, so muting the
      // tickers freezes all of them at their opening frame without any of
      // them needing to know why.
      child: TickerMode(enabled: enabled, child: layers),
    );
  }
}

class _Layers extends StatelessWidget {
  const _Layers({
    required this.condition,
    required this.isNight,
    this.scroll = 0,
  });

  final WeatherCondition condition;
  final bool isNight;
  final double scroll;

  /// Clouds and precipitation drift slowly against the scroll; the sun moves
  /// faster, which is what sells the parallax.
  double get _slow => scroll * Motion.parallaxSlow;
  double get _fast => scroll * Motion.parallaxFast;

  /// A cloud is white by day and near-black at night, matching the design's
  /// `cloudColor` switch.
  Color _cloud(double opacity) =>
      (isNight ? const Color(0xFF1E2028) : Colors.white).withValues(
        alpha: opacity,
      );

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [Positioned.fill(child: Stack(children: _forCondition()))],
      ),
    );
  }

  List<Widget> _forCondition() => switch (condition) {
    WeatherCondition.clear when isNight => [
      const Positioned.fill(child: ParticleLayer.stars(count: 8)),
      MoonLayer(parallax: _fast),
    ],
    WeatherCondition.clear => [
      ..._defaultClouds(),
      SunLayer(parallax: _fast),
      ..._nightStars(),
    ],
    WeatherCondition.cloudy => [
      DriftingBlob(
        top: 50,
        startLeft: -65,
        width: 190,
        height: 62,
        period: const Duration(seconds: 16),
        color: _cloud(0.6),
        blurSigma: 1.5,
        parallax: _slow,
      ),
      DriftingBlob(
        top: 110,
        startLeft: -105,
        width: 150,
        height: 52,
        period: const Duration(seconds: 20),
        delay: const Duration(seconds: 2),
        color: _cloud(0.5),
        blurSigma: 1.5,
        parallax: _slow,
      ),
      DriftingBlob(
        top: 20,
        startLeft: -45,
        width: 110,
        height: 40,
        period: const Duration(seconds: 24),
        delay: const Duration(seconds: 5),
        color: _cloud(0.4),
        blurSigma: 1.5,
        parallax: _slow,
      ),
      ..._nightStars(),
    ],
    WeatherCondition.fog => [
      _fogBand(40, 22, 0, 0.55),
      _fogBand(85, 26, 4, 0.45),
      _fogBand(130, 30, 8, 0.5),
      _fogBand(175, 24, 12, 0.4),
    ],
    WeatherCondition.drizzle => [
      DriftingBlob(
        top: 40,
        startLeft: -60,
        width: 180,
        height: 58,
        period: const Duration(seconds: 20),
        color: _cloud(0.5),
        blurSigma: 1.5,
        parallax: _slow,
      ),
      DriftingBlob(
        top: 95,
        startLeft: -90,
        width: 120,
        height: 44,
        period: const Duration(seconds: 26),
        delay: const Duration(seconds: 3),
        color: _cloud(0.4),
        blurSigma: 1.5,
        parallax: _slow,
      ),
      Positioned.fill(child: ParticleLayer.rain(count: 8, parallax: _slow)),
      ..._nightStars(),
    ],
    WeatherCondition.rain => [
      DriftingBlob(
        top: 40,
        startLeft: -70,
        width: 200,
        height: 64,
        period: const Duration(seconds: 14),
        color: _cloud(0.55),
        blurSigma: 1.5,
        parallax: _slow,
      ),
      DriftingBlob(
        top: 95,
        startLeft: -100,
        width: 140,
        height: 50,
        period: const Duration(seconds: 18),
        delay: const Duration(seconds: 2),
        color: _cloud(0.45),
        blurSigma: 1.5,
        parallax: _slow,
      ),
      Positioned.fill(child: ParticleLayer.rain(count: 10, parallax: _slow)),
    ],
    WeatherCondition.snow => [
      DriftingBlob(
        top: 40,
        startLeft: -60,
        width: 170,
        height: 56,
        period: const Duration(seconds: 30),
        color: _cloud(0.5),
        blurSigma: 1.5,
        parallax: _slow,
      ),
      Positioned.fill(child: ParticleLayer.snow(count: 12, parallax: _slow)),
    ],
    WeatherCondition.storm => [
      DriftingBlob(
        top: 30,
        startLeft: -75,
        width: 220,
        height: 70,
        period: const Duration(seconds: 10),
        color: _cloud(0.65),
        blurSigma: 1.5,
        parallax: _slow,
      ),
      DriftingBlob(
        top: 90,
        startLeft: -115,
        width: 160,
        height: 56,
        period: const Duration(seconds: 13),
        delay: const Duration(milliseconds: 1500),
        color: _cloud(0.55),
        blurSigma: 1.5,
        parallax: _slow,
      ),
      DriftingBlob(
        top: 70,
        startLeft: -50,
        width: 130,
        height: 44,
        period: const Duration(seconds: 11),
        delay: const Duration(seconds: 3),
        color: _cloud(0.45),
        blurSigma: 1.5,
        parallax: _slow,
      ),
      const Positioned.fill(child: StormLayer()),
    ],
  };

  /// The two clouds that accompany a clear day.
  List<Widget> _defaultClouds() => [
    DriftingBlob(
      top: 60,
      startLeft: -50,
      width: 150,
      height: 56,
      period: const Duration(seconds: 30),
      color: _cloud(0.4),
      blurSigma: 1.5,
      parallax: _slow,
    ),
    DriftingBlob(
      top: 130,
      startLeft: -90,
      width: 110,
      height: 42,
      period: const Duration(seconds: 42),
      delay: const Duration(seconds: 6),
      color: _cloud(0.3),
      blurSigma: 1.5,
      parallax: _slow,
    ),
  ];

  /// A few stars still show through a cloudy or rainy night.
  List<Widget> _nightStars() => isNight
      ? [Positioned.fill(child: ParticleLayer.stars(count: 3, parallax: _slow))]
      : const [];

  Widget _fogBand(
    double top,
    int periodSeconds,
    int delaySeconds,
    double opacity,
  ) {
    return DriftingBlob(
      top: top,
      startLeft: -120,
      width: 520,
      height: 46,
      period: Duration(seconds: periodSeconds),
      delay: Duration(seconds: delaySeconds),
      color: _cloud(opacity),
      blurSigma: 10,
      parallax: _slow,
    );
  }
}
