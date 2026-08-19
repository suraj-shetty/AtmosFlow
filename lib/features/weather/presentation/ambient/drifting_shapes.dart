import 'dart:ui';

import 'package:flutter/material.dart';

/// A blurred blob that drifts left→right forever — the design's
/// `@keyframes cloudDrift{from{translateX(-20%)}to{translateX(120%)}}`.
///
/// Clouds and fog bands are the same shape at different sizes and opacities,
/// so both use this.
class DriftingBlob extends StatefulWidget {
  const DriftingBlob({
    super.key,
    required this.top,
    required this.width,
    required this.height,
    required this.period,
    required this.color,
    this.startLeft = 0,
    this.delay = Duration.zero,
    this.blurSigma = 1.5,
    this.parallax = 0,
  });

  /// Distance from the top of the sky.
  final double top;
  final double width;
  final double height;
  final Duration period;
  final Color color;

  /// The blob's resting x offset before the drift is applied — the CSS
  /// `left:-50px` that starts a cloud off-screen.
  final double startLeft;

  final Duration delay;
  final double blurSigma;

  /// Vertical shift already scaled by the parallax multiplier.
  final double parallax;

  @override
  State<DriftingBlob> createState() => _DriftingBlobState();
}

class _DriftingBlobState extends State<DriftingBlob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A muted ticker means Reduce Motion, or a golden. Hold the opening frame
    // rather than starting a drift that can never advance — and, more to the
    // point, rather than leaving a stagger timer pending that nothing will
    // ever fire.
    if (_started || !TickerMode.of(context)) return;
    _started = true;
    _start();
  }

  Future<void> _start() async {
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
      if (!mounted) return;
    }
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skyWidth = MediaQuery.sizeOf(context).width;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // -20% → 120% of the blob's own width, across the full sky.
        final travel = skyWidth + widget.width * 1.4;
        final x =
            widget.startLeft - widget.width * 0.2 + _controller.value * travel;
        return Positioned(
          top: widget.top + widget.parallax,
          left: x,
          child: child!,
        );
      },
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: widget.blurSigma,
          sigmaY: widget.blurSigma,
        ),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
