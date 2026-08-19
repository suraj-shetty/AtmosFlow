import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// The design fades and lifts every screen body on entry:
/// `opacity 0→1` and `translateY(10px)→0` over 400ms.
///
/// Wraps a screen's content rather than the route, so it also plays when a
/// tab is re-selected.
class ScreenTransition extends StatefulWidget {
  const ScreenTransition({super.key, required this.child});

  final Widget child;

  @override
  State<ScreenTransition> createState() => _ScreenTransitionState();
}

class _ScreenTransitionState extends State<ScreenTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.screenTransition,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Motion.screenTransitionCurve,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: _controller.value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - curved.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// `@keyframes fadeSlideUp` — an 18px rise used by the Home metric grid, with
/// a per-tile [delay] producing the 0/60/120/180ms stagger.
class FadeSlideUp extends StatelessWidget {
  const FadeSlideUp({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.fadeSlideUp + delay,
      curve: Interval(
        delay.inMilliseconds / (Motion.fadeSlideUp + delay).inMilliseconds,
        1,
        curve: Curves.easeOut,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, Motion.fadeSlideUpOffset * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
