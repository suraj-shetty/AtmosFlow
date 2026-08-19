import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/motion.dart';
import '../../../../../core/widgets/section_label.dart';

/// The sun's arc across the day, with a dot that sweeps to the current
/// position on an ease-out cubic — `1-(1-t)³` in the prototype.
class SunPath extends StatefulWidget {
  const SunPath({
    super.key,
    required this.sunrise,
    required this.sunset,
    required this.progress,
    required this.textColor,
    required this.subColor,
    required this.trackColor,
    required this.arcColor,
    this.animate = true,
  });

  final DateTime sunrise;
  final DateTime sunset;

  /// 0–1 through the daylight window.
  final double progress;

  final Color textColor;
  final Color subColor;

  /// The untravelled remainder of the arc.
  final Color trackColor;

  /// The travelled portion, and the sun itself.
  final Color arcColor;

  final bool animate;

  @override
  State<SunPath> createState() => _SunPathState();
}

class _SunPathState extends State<SunPath> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.arcSweep,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      _controller.value = 1;
      return;
    }
    Future<void>.delayed(Motion.detailChartDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        SectionLabel('Sun path', color: widget.subColor),
        SizedBox(
          height: 140,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _SunPathPainter(
                progress:
                    widget.progress *
                    Motion.arcSweepCurve.transform(_controller.value),
                trackColor: widget.trackColor,
                arcColor: widget.arcColor,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sunrise ${time.format(widget.sunrise)}',
              style: TextStyle(fontSize: 12, color: widget.subColor),
            ),
            Text(
              'Sunset ${time.format(widget.sunset)}',
              style: TextStyle(fontSize: 12, color: widget.subColor),
            ),
          ],
        ),
      ],
    );
  }
}

class _SunPathPainter extends CustomPainter {
  _SunPathPainter({
    required this.progress,
    required this.trackColor,
    required this.arcColor,
  });

  final double progress;
  final Color trackColor;
  final Color arcColor;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width / 2 - 16, size.height - 20);
    final centre = Offset(size.width / 2, size.height - 10);
    final rect = Rect.fromCircle(center: centre, radius: radius);

    // The whole arc as a faint dashed-free track…
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = trackColor,
    );

    // …and the part the sun has already travelled, in the accent. Drawing
    // both makes the arc read as progress rather than as decoration, and
    // means it no longer depends on one pale tint being visible.
    if (progress > 0) {
      canvas.drawArc(
        rect,
        math.pi,
        math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..color = arcColor,
      );
    }

    // Sunrise sits at π (left) and sunset at 0 (right).
    final angle = math.pi - progress * math.pi;
    final dot = Offset(
      centre.dx + radius * math.cos(angle),
      centre.dy - radius * math.sin(angle),
    );
    // A halo lifts the sun off whichever card it lands on.
    canvas.drawCircle(
      dot,
      11,
      Paint()..color = arcColor.withValues(alpha: 0.22),
    );
    canvas.drawCircle(dot, 7, Paint()..color = arcColor);
  }

  @override
  bool shouldRepaint(_SunPathPainter old) =>
      old.progress != progress ||
      old.arcColor != arcColor ||
      old.trackColor != trackColor;
}
