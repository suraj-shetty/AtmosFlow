import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Colours and geometry from the brand design's icon master.
///
/// The same numbers are rasterised into the app icon and the OS launch image
/// by `tool/brand/render.py`, so the mark Flutter draws on the splash is the
/// one the launch image already put on screen — that is what lets the handoff
/// have no seam.
abstract final class Brand {
  static const dawnSky = [Color(0xFF8FC4E8), Color(0xFFF2D3AE), Color(0xFFE8A06A)];
  static const dawnSkyStops = [0.0, 0.58, 1.0];

  /// The splash sky: the icon's gradient with one more stop and a shallower
  /// angle, because a phone screen is a much taller box than an icon.
  static const splashSky = [
    Color(0xFF7DB4E0),
    Color(0xFFBCD2E6),
    Color(0xFFF2D3AE),
    Color(0xFFE8A06A),
  ];
  static const splashSkyStops = [0.0, 0.40, 0.76, 1.0];
  static const splashAngle = 172.0;

  static const nightSky = [Color(0xFF26304F), Color(0xFF141A30)];
  static const nightSkyStops = [0.0, 1.0];

  /// The tile is the icon one step lighter, so it reads as an object on the
  /// sky rather than a hole cut in it.
  static const tileSky = [Color(0xFFA8D0EC), Color(0xFFF6DCBC), Color(0xFFE29257)];
  static const tileAngle = 168.0;

  static const sunCore = Color(0xFFFFF6E6);
  static const sunEdge = Color(0xFFC67139);
  static const moon = Color(0xFFF4F0E2);
  static const nightInk = Color(0xFF141A30);
  static const ink = Color(0xFF201E1D);

  static const tileSize = 78.0;
  static const tileRadius = 22.0;
}

/// Reproduces `linear-gradient(<angle>deg, …)` for a box of [size].
///
/// CSS measures from "up" and turns clockwise, and sizes the gradient line so
/// it covers the box's corners — neither of which is Flutter's default, and
/// both of which show on a screen-tall gradient as a visibly wrong tilt.
LinearGradient cssLinearGradient({
  required double angle,
  required List<Color> colors,
  required List<double> stops,
  required Size size,
}) {
  final radians = angle * math.pi / 180;
  final dx = math.sin(radians);
  final dy = -math.cos(radians);
  final length = (size.width * dx).abs() + (size.height * dy).abs();
  final ax = size.width == 0 ? 0.0 : length * dx / size.width;
  final ay = size.height == 0 ? 0.0 : length * dy / size.height;
  return LinearGradient(
    begin: Alignment(-ax, -ay),
    end: Alignment(ax, ay),
    colors: colors,
    stops: stops,
  );
}

/// A CSS `radial-gradient(circle at x% y%, …)`, whose default sizing runs out
/// to the box's farthest corner rather than its nearest edge.
RadialGradient cssRadialGradient({
  required double centreX,
  required double centreY,
  required List<Color> colors,
  required List<double> stops,
}) {
  final far = math.sqrt(
    math.pow(math.max(centreX, 1 - centreX), 2) +
        math.pow(math.max(centreY, 1 - centreY), 2),
  );
  return RadialGradient(
    center: Alignment(centreX * 2 - 1, centreY * 2 - 1),
    // Flutter measures a radial gradient's radius against the box's whole
    // shorter side, so the farthest-corner distance goes in as the fraction
    // of the box it already is.
    radius: far,
    colors: colors,
    stops: stops,
  );
}

/// CSS blur radius → the blur Flutter's [BoxShadow] wants.
///
/// CSS spreads a shadow over twice its sigma; Flutter converts the other way
/// again on the way in. Without this the launch image's shadow and the one
/// Flutter draws a frame later are visibly different softnesses.
double cssBlur(double radius) => math.max(0, (radius / 2 - 0.5) / 0.57735);

/// The mark on its rounded tile: a low sun over two bands of air.
///
/// [drift] runs 0→1 forever and carries the design's idle motion — the sun
/// breathing, the bands sliding past each other. Pass null to hold it still.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = Brand.tileSize,
    this.night = false,
    this.drift,
    this.shadow = true,
  });

  final double size;
  final bool night;
  final Animation<double>? drift;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final unit = size / Brand.tileSize;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Brand.tileRadius * unit),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: const Color(0x29201E1D), // rgba(32,30,29,.16)
                  offset: Offset(0, 8 * unit),
                  blurRadius: cssBlur(24 * unit),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Brand.tileRadius * unit),
        child: SizedBox(
          width: size,
          height: size,
          child: night ? _Crescent(unit: unit) : _Sun(unit: unit, drift: drift),
        ),
      ),
    );
  }
}

class _Sun extends StatelessWidget {
  const _Sun({required this.unit, this.drift});

  final double unit;
  final Animation<double>? drift;

  @override
  Widget build(BuildContext context) {
    const tile = Brand.tileSize;
    final sky = DecoratedBox(
      decoration: BoxDecoration(
        gradient: cssLinearGradient(
          angle: Brand.tileAngle,
          colors: Brand.tileSky,
          stops: const [0.0, 0.58, 1.0],
          size: Size(tile * unit, tile * unit),
        ),
      ),
      child: const SizedBox.expand(),
    );

    final sun = Positioned(
      left: (tile / 2 - 15) * unit,
      top: 0.31 * tile * unit,
      width: 30 * unit,
      height: 30 * unit,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: cssRadialGradient(
            centreX: 0.36,
            centreY: 0.32,
            colors: const [Brand.sunCore, Brand.sunEdge],
            stops: const [0.0, 0.9],
          ),
        ),
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        sky,
        if (drift == null)
          sun
        else
          AnimatedBuilder(
            animation: drift!,
            // `@keyframes afSunPulse` — 1 → 1.06 and back, over the cycle.
            builder: (context, child) => Transform.scale(
              scale: 1 + 0.06 * _pingPong(drift!.value),
              child: child,
            ),
            child: Stack(fit: StackFit.expand, children: [sun]),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 15 * unit,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 4 * unit,
            children: [
              _bar(35 * unit, 4 * unit, 0.94, -3, 4),
              _bar(47 * unit, 4 * unit, 0.80, 4, -3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bar(double w, double h, double alpha, double from, double to) {
    final bar = Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(999),
      ),
    );
    if (drift == null) return bar;
    return AnimatedBuilder(
      animation: drift!,
      // `@keyframes afBar1` / `afBar2` — the two slide opposite ways, which is
      // what makes a pair of straight lines read as moving air.
      builder: (context, child) => Transform.translate(
        offset: Offset(
          (from + (to - from) * _pingPong(drift!.value)) * unit,
          0,
        ),
        child: child,
      ),
      child: bar,
    );
  }
}

/// The same mark after dark: a crescent, cut by lifting a disc of night sky
/// across the moon.
class _Crescent extends StatelessWidget {
  const _Crescent({required this.unit});

  final double unit;

  @override
  Widget build(BuildContext context) {
    const tile = Brand.tileSize;
    final side = tile * unit;
    final disc = 0.40 * side;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: cssLinearGradient(
              angle: Brand.tileAngle,
              colors: Brand.nightSky,
              stops: Brand.nightSkyStops,
              size: Size(side, side),
            ),
          ),
          child: const SizedBox.expand(),
        ),
        Positioned(
          left: 0.34 * side,
          top: 0.26 * side,
          width: disc,
          height: disc,
          child: const DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: Brand.moon),
          ),
        ),
        Positioned(
          left: 0.22 * side,
          top: 0.20 * side,
          width: disc,
          height: disc,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Brand.nightInk,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0.19 * side,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 0.08 * side,
            children: [
              _bar(0.44 * side, 0.07 * side, 0.9),
              _bar(0.60 * side, 0.07 * side, 0.6),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bar(double w, double h, double alpha) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: Brand.moon.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(999),
    ),
  );
}

/// 0 → 1 → 0, the shape of a CSS keyframe that names the same value at 0% and
/// 100% with a different one at 50%.
double _pingPong(double t) => 1 - (2 * t - 1).abs();
