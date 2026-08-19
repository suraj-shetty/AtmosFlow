import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/glass.dart';
import '../../../../../core/theme/motion.dart';

/// The floating puck that drops in over the sky while the forecast reloads.
///
/// `refreshOverlayStyle` in the design: a 44px glass circle centred at the top
/// of the screen, which springs down from 46px above at 60% scale and fades in
/// behind it. Its icon plays a single `sunSpinBounce` turn each time a refresh
/// starts.
class RefreshPuck extends StatelessWidget {
  const RefreshPuck({
    super.key,
    required this.refreshing,
    required this.icon,
    required this.color,
  });

  final bool refreshing;

  /// The design shows the sun for a clear sky and a cloud for everything else.
  final IconData icon;

  /// `hp.accentText` — the sky's own accent, so the puck belongs to it.
  final Color color;

  @override
  Widget build(BuildContext context) {
    // The design puts the puck at `top:20`, which its preview frame can get
    // away with. A real notch or dynamic island sits exactly there, so the
    // puck drops to the first clear line below the status bar instead — the
    // same "floating over the sky, above the content" reading, still visible.
    final safeTop = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: math.max(20, safeTop),
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: AnimatedOpacity(
            opacity: refreshing ? 1 : 0,
            duration: Motion.refreshPuckFade,
            curve: Curves.ease,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: refreshing ? 1.0 : 0.0),
              duration: Motion.refreshPuckSlide,
              // Overshoots past 1, which is what gives the drop its bounce.
              curve: Motion.tabBounceCurve,
              builder: (context, t, child) => Transform.translate(
                offset: Offset(0, -Motion.refreshPuckHiddenLift * (1 - t)),
                child: Transform.scale(
                  scale:
                      Motion.refreshPuckHiddenScale +
                      (1 - Motion.refreshPuckHiddenScale) * t,
                  child: child,
                ),
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: GlassSurface.glassFilter(dark: false),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.55),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    child: _SpinBounce(
                      active: refreshing,
                      child: Icon(icon, size: 22, color: color),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `@keyframes sunSpinBounce` — a full turn that runs ahead of itself and
/// swells to 1.2× before settling back. Played once per refresh.
class _SpinBounce extends StatefulWidget {
  const _SpinBounce({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_SpinBounce> createState() => _SpinBounceState();
}

class _SpinBounceState extends State<_SpinBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.refreshSpin,
  );

  // 0% 0deg/1 → 30% 160deg/1.2 → 60% 280deg/.92 → 100% 360deg/1.
  late final Animation<double> _turns = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 160 / 360), weight: 30),
    TweenSequenceItem(
      tween: Tween(begin: 160 / 360, end: 280 / 360),
      weight: 30,
    ),
    TweenSequenceItem(tween: Tween(begin: 280 / 360, end: 1.0), weight: 40),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.92), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0), weight: 40),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didUpdateWidget(_SpinBounce old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _turns,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
