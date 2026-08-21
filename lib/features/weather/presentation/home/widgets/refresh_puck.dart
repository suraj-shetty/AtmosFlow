import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/glass.dart';
import '../../../../../core/theme/motion.dart';

/// The floating puck that drops in over the sky while the forecast reloads —
/// and, before that, the bubble the pull gesture draws out of the top edge.
///
/// `refreshOverlayStyle` in the design: a 44px glass circle centred at the top
/// of the screen, which springs down from 46px above at 60% scale and fades in
/// behind it. Its icon plays a single `sunSpinBounce` turn each time a refresh
/// starts.
///
/// The design has nothing for the pull itself, which left the gesture with no
/// feedback at all until it completed. The bubble is the same circle, drawn
/// early: it swells out of the top edge as a stretched droplet, rounds off and
/// fills a ring as the finger approaches the trigger, and is still on screen
/// in the same place when [refreshing] takes over — so the two read as one
/// object rather than a handoff.
class RefreshPuck extends StatefulWidget {
  const RefreshPuck({
    super.key,
    required this.refreshing,
    required this.pull,
    required this.icon,
    required this.color,
  });

  final bool refreshing;

  /// 0 at rest, 1 at the point a release starts a refresh. See `PullToRefresh`.
  final ValueListenable<double> pull;

  /// The design shows the sun for a clear sky and a cloud for everything else.
  final IconData icon;

  /// `hp.accentText` — the sky's own accent, so the puck belongs to it.
  final Color color;

  @override
  State<RefreshPuck> createState() => _RefreshPuckState();
}

class _RefreshPuckState extends State<RefreshPuck>
    with SingleTickerProviderStateMixin {
  /// The design's own entrance and exit, for the refresh itself. A refresh
  /// started by a tap never touched the bubble, so this has to carry the puck
  /// in on its own — and it is what takes the puck back out either way.
  late final AnimationController _settle = AnimationController(
    vsync: this,
    value: widget.refreshing ? 1 : 0,
    duration: Motion.refreshPuckSlide,
    reverseDuration: Motion.refreshPuckFade,
  );

  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _settle,
    curve: Motion.tabBounceCurve,
    reverseCurve: Curves.easeIn.flipped,
  );

  @override
  void didUpdateWidget(RefreshPuck old) {
    super.didUpdateWidget(old);
    if (widget.refreshing == old.refreshing) return;
    if (widget.refreshing) {
      _settle.forward();
    } else {
      _settle.reverse();
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _settle.dispose();
    super.dispose();
  }

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
          child: AnimatedBuilder(
            animation: Listenable.merge([_curved, widget.pull]),
            builder: (context, child) {
              final pulled = widget.pull.value;
              final settled = _curved.value;

              // Whichever of the two has the puck further in owns it, so the
              // release hands over without the circle dipping between them.
              final progress = math.max(settled, pulled.clamp(0.0, 1.0));
              // A refresh that has only just started is still at zero: it
              // keeps the puck so the spring has something to move.
              if (progress <= 0 && !widget.refreshing) {
                return const SizedBox(width: 44, height: 44);
              }

              return _Bubble(
                progress: progress,
                overshoot: _settle.isDismissed
                    ? (pulled - 1).clamp(0.0, 0.35)
                    : 0,
                // The droplet only stretches while the finger is drawing it
                // out; once a refresh owns the puck it is a circle.
                stretch: _settle.isDismissed,
                ring: _settle.isDismissed ? pulled.clamp(0.0, 1.0) : 0,
                color: widget.color,
                child: child!,
              );
            },
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
                    active: widget.refreshing,
                    child: Icon(widget.icon, size: 22, color: widget.color),
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

/// Places the puck for one value of [progress].
///
/// Early on it is a droplet: stretched taller than it is wide, still half-way
/// into the top edge, fading up. By the time it is fully out it has rounded
/// off, dropped to its resting line and closed its ring.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.progress,
    required this.overshoot,
    required this.stretch,
    required this.ring,
    required this.color,
    required this.child,
  });

  final double progress;
  final double overshoot;
  final bool stretch;
  final double ring;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Rises out of the edge rather than appearing on it, and keeps a little
    // give past the trigger so the gesture never feels like it has hit a wall.
    final lift =
        -Motion.refreshPuckHiddenLift * (1 - progress) + 10 * overshoot;
    final scale =
        Motion.refreshPuckHiddenScale +
        (1 - Motion.refreshPuckHiddenScale) * progress;
    final squash = stretch ? 0.22 * (1 - progress) : 0.0;

    return Opacity(
      opacity: (progress / 0.3).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, lift),
        child: Transform.scale(
          scaleX: scale * (1 - squash),
          scaleY: scale * (1 + squash),
          child: CustomPaint(
            foregroundPainter: ring <= 0 || ring >= 1
                ? null
                : _PullRingPainter(progress: ring, color: color),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The hairline arc that closes around the bubble as the pull completes.
class _PullRingPainter extends CustomPainter {
  _PullRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - 2,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_PullRingPainter old) =>
      old.progress != progress || old.color != color;
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
