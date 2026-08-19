import 'package:flutter/material.dart';

import '../../../../../core/theme/atmos_tokens.dart';
import '../../../../../core/theme/motion.dart';

/// The day's temperature curve, drawing itself on from left to right.
///
/// The design does this with `stroke-dasharray: 1000; stroke-dashoffset:
/// 1000 → 0`; here the equivalent is extracting a growing sub-path from the
/// line's [PathMetric], which gives the same reveal without guessing at a
/// dash length.
class TemperatureChart extends StatefulWidget {
  const TemperatureChart({
    super.key,
    required this.temperatures,
    required this.subLabelColor,
    this.animate = true,
  });

  final List<double> temperatures;
  final Color subLabelColor;
  final bool animate;

  @override
  State<TemperatureChart> createState() => _TemperatureChartState();
}

class _TemperatureChartState extends State<TemperatureChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.graphDraw,
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
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 140,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _TemperatureChartPainter(
                values: widget.temperatures,
                progress: Motion.graphDrawCurve.transform(_controller.value),
                lineColor: tokens.accentRamp.s600,
                fillTop: tokens.accentRamp.s400.withValues(alpha: 0.5),
                fillBottom: tokens.accentRamp.s100.withValues(alpha: 0),
              ),
              size: Size.infinite,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in ['12AM', '6AM', '12PM', '6PM', '11PM'])
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: widget.subLabelColor),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TemperatureChartPainter extends CustomPainter {
  _TemperatureChartPainter({
    required this.values,
    required this.progress,
    required this.lineColor,
    required this.fillTop,
    required this.fillBottom,
  });

  final List<double> values;
  final double progress;
  final Color lineColor;
  final Color fillTop;
  final Color fillBottom;

  static const double _pad = 12;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final points = _points(size);
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }

    // The gradient fill fades in behind the line, on a slight delay.
    final fillOpacity = ((progress - 0.25) / 0.75).clamp(0.0, 1.0);
    if (fillOpacity > 0) {
      final area = Path.from(line)
        ..lineTo(points.last.dx, size.height - _pad)
        ..lineTo(points.first.dx, size.height - _pad)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              fillTop.withValues(alpha: fillTop.a * fillOpacity),
              fillBottom,
            ],
          ).createShader(Offset.zero & size),
      );
    }

    canvas.drawPath(
      _partial(line, progress),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = lineColor,
    );
  }

  List<Offset> _points(Size size) {
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final range = max - min == 0 ? 1 : max - min;
    final stepX = (size.width - _pad * 2) / (values.length - 1);

    return [
      for (var i = 0; i < values.length; i++)
        Offset(
          _pad + i * stepX,
          _pad + (size.height - _pad * 2) * (1 - (values[i] - min) / range),
        ),
    ];
  }

  /// The first [t] of a path, by length.
  static Path _partial(Path path, double t) {
    if (t >= 1) return path;
    final out = Path();
    for (final metric in path.computeMetrics()) {
      out.addPath(metric.extractPath(0, metric.length * t), Offset.zero);
    }
    return out;
  }

  @override
  bool shouldRepaint(_TemperatureChartPainter old) =>
      old.progress != progress || old.values != values;
}
