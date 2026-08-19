import 'package:flutter/material.dart';

import '../../../../core/theme/motion.dart';

/// The lightning bolt and the sky flash behind it, both on the design's 3.2s
/// `lightningFlash` / `skyFlash` timeline: dark until 88%, then a double
/// strike at 89%, 90% and 91% before fading by 93%.
class StormLayer extends StatefulWidget {
  const StormLayer({
    super.key,
    this.boltTop = 60,
    this.boltLeftFraction = 0.56,
  });

  final double boltTop;
  final double boltLeftFraction;

  @override
  State<StormLayer> createState() => _StormLayerState();
}

class _StormLayerState extends State<StormLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.lightningCycle,
  )..repeat();

  /// The keyframe stops as fractions of the cycle, and the opacity at each.
  static const _stops = <(double, double)>[
    (0.00, 0),
    (0.88, 0),
    (0.89, 1),
    (0.90, 0.1),
    (0.91, 1),
    (0.93, 0),
    (1.00, 0),
  ];

  static double _opacityAt(double t, double scale) {
    for (var i = 0; i < _stops.length - 1; i++) {
      final (t0, v0) = _stops[i];
      final (t1, v1) = _stops[i + 1];
      if (t >= t0 && t <= t1) {
        final local = t1 == t0 ? 0.0 : (t - t0) / (t1 - t0);
        return (v0 + (v1 - v0) * local) * scale;
      }
    }
    return 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          children: [
            // The whole sky lifts at 35% white on the strike.
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Colors.white.withValues(
                    alpha: _opacityAt(t, 0.35).clamp(0.0, 1.0),
                  ),
                ),
              ),
            ),
            Positioned(
              top: widget.boltTop,
              left: MediaQuery.sizeOf(context).width * widget.boltLeftFraction,
              child: Opacity(
                opacity: _opacityAt(t, 1).clamp(0.0, 1.0),
                child: child,
              ),
            ),
          ],
        );
      },
      child: const _Bolt(width: 34, height: 54),
    );
  }
}

/// The bolt's `clip-path: polygon(60% 0, 20% 55%, 45% 55%, 10% 100%, 80% 40%,
/// 50% 40%)`, with the CSS's two stacked glows.
class _Bolt extends StatelessWidget {
  const _Bolt({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: const _BoltPainter(),
    );
  }
}

class _BoltPainter extends CustomPainter {
  const _BoltPainter();

  static const _points = <Offset>[
    Offset(0.60, 0.00),
    Offset(0.20, 0.55),
    Offset(0.45, 0.55),
    Offset(0.10, 1.00),
    Offset(0.80, 0.40),
    Offset(0.50, 0.40),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < _points.length; i++) {
      final p = Offset(_points[i].dx * size.width, _points[i].dy * size.height);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();

    // drop-shadow(0 0 10px #fff) drop-shadow(0 0 18px #ffe9a3)
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFE9A3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFF8DC));
  }

  @override
  bool shouldRepaint(_BoltPainter old) => false;
}

/// The moon disc with its glow, drawn at the top right of a night sky.
class MoonLayer extends StatelessWidget {
  const MoonLayer({super.key, this.parallax = 0});

  final double parallax;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 30 + parallax,
      right: 30,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF9F4ED),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.4),
              blurRadius: 24,
            ),
          ],
        ),
      ),
    );
  }
}
