import 'package:flutter/material.dart';

/// Falling rain and snow, and the twinkling star field — every particle effect
/// in the sky, painted rather than composed from widgets so a hundred moving
/// dots cost one repaint.
class ParticleLayer extends StatefulWidget {
  const ParticleLayer.rain({super.key, required this.count, this.parallax = 0})
    : kind = ParticleKind.rain;

  const ParticleLayer.snow({super.key, required this.count, this.parallax = 0})
    : kind = ParticleKind.snow;

  const ParticleLayer.stars({super.key, required this.count, this.parallax = 0})
    : kind = ParticleKind.star;

  final ParticleKind kind;
  final int count;
  final double parallax;

  @override
  State<ParticleLayer> createState() => _ParticleLayerState();
}

enum ParticleKind { rain, snow, star }

class _ParticleLayerState extends State<ParticleLayer>
    with SingleTickerProviderStateMixin {
  // One long cycle; each particle reads it at its own phase and rate, which is
  // how the CSS staggers `animation-delay` across the drops.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ParticlePainter(
            kind: widget.kind,
            count: widget.count,
            t: _controller.value,
            parallax: widget.parallax,
            isDarkGround: Theme.of(context).brightness == Brightness.dark,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.kind,
    required this.count,
    required this.t,
    required this.parallax,
    required this.isDarkGround,
  });

  final ParticleKind kind;
  final int count;
  final double t;
  final double parallax;
  final bool isDarkGround;

  /// `@keyframes rainFall` / `snowFall` both travel 340px.
  static const double _fallDistance = 340;

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case ParticleKind.rain:
        _paintRain(canvas, size);
      case ParticleKind.snow:
        _paintSnow(canvas, size);
      case ParticleKind.star:
        _paintStars(canvas, size);
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    for (var i = 0; i < count; i++) {
      // Matches `drop(8 + i*9, 1.1 + (i%3)*0.3, i*0.15)` in the prototype.
      final x = size.width * ((8 + i * 9) / 100);
      final period = 1.1 + (i % 3) * 0.3;
      final delay = i * 0.15;
      final phase = _phase(period, delay);

      final y = -20 + phase * _fallDistance + parallax;
      // opacity .8 → .2 over the fall
      paint.color = Colors.white.withValues(alpha: 0.8 - 0.6 * phase);
      canvas.drawLine(Offset(x, y), Offset(x, y + 16), paint);
    }
  }

  void _paintSnow(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      // `flake(4 + i*8, 4 + (i%4), i*0.3, 3 + (i%3))`
      final baseX = size.width * ((4 + i * 8) / 100);
      final period = (4 + (i % 4)).toDouble();
      final delay = i * 0.3;
      final radius = (3 + (i % 3)) / 2;
      final phase = _phase(period, delay);

      // snowFall drifts 12px right over the fall.
      final x = baseX + 12 * phase;
      final y = -10 + phase * _fallDistance + parallax;
      paint.color = (isDarkGround ? Colors.white : const Color(0xFF728157))
          .withValues(alpha: 0.9 - 0.6 * phase);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _paintStars(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < count; i++) {
      final x = size.width * _starX[i % _starX.length];
      final y = size.height * _starY[i % _starY.length];
      final radius = (i % 3 == 0 ? 3 : 2) / 2;
      final period = 3.0 + (i % 5) * 0.5;
      final delay = (i % 4) * 0.5;

      // `@keyframes twinkle{0%,100%{opacity:.2}50%{opacity:1}}`
      final phase = _phase(period, delay);
      final opacity = 0.2 + 0.8 * (1 - (2 * phase - 1).abs());
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y + parallax), radius, paint);
    }
  }

  /// Where a particle with this [period] and [delay] sits in its own 0–1 cycle
  /// at the shared clock's current position.
  double _phase(double period, double delay) {
    const cycleSeconds = 12.0;
    final seconds = t * cycleSeconds + delay;
    return (seconds % period) / period;
  }

  // The star positions the design hand-places, as fractions of the sky.
  static const _starX = [0.20, 0.70, 0.50, 0.35, 0.85, 0.80, 0.12, 0.60];
  static const _starY = [0.15, 0.22, 0.10, 0.30, 0.35, 0.08, 0.26, 0.40];

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.t != t || old.count != count || old.parallax != parallax;
}
