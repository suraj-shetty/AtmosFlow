import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// The design fades and lifts every screen body on entry:
/// `opacity 0→1` and `translateY(10px)→0` over 400ms.
///
/// Wraps a screen's content rather than the route, so it also plays when a
/// tab is re-selected.
///
/// Pass the screen's own [background] rather than painting it outside: a
/// partial opacity forces the subtree into its own compositing layer, and a
/// `BackdropFilter` inside that layer — every glass card in this app — has
/// nothing to sample and blurs empty pixels, which reads as a dark wash over
/// each card until the fade finishes. Handing the background in puts it
/// inside that layer, where the blur can find it. The same decoration is also
/// painted underneath at full opacity, so what fades in is only the content.
class ScreenTransition extends StatefulWidget {
  const ScreenTransition({super.key, required this.child, this.background});

  final Widget child;

  /// The screen's ground — the gradient it would otherwise sit on.
  final Decoration? background;

  @override
  State<ScreenTransition> createState() => _ScreenTransitionState();
}

class _ScreenTransitionState extends State<ScreenTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.screenTransition,
  )..forward();

  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _controller,
    curve: Motion.screenTransitionCurve,
  );

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.background;

    // Inside the fading layer, under the content, so every glass surface has
    // a backdrop to blur for the whole of the fade.
    Widget body = widget.child;
    if (background != null) {
      body = DecoratedBox(decoration: background, child: body);
    }

    // One shared backdrop for every glass surface on the screen — see
    // [GlassSurface].
    body = BackdropGroup(child: body);

    final Widget content = AnimatedBuilder(
      animation: _curved,
      builder: (context, child) => Opacity(
        opacity: _controller.value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - _curved.value)),
          child: child,
        ),
      ),
      child: body,
    );

    if (background == null) return content;

    // …and again behind it at full strength, so the ground itself never fades
    // and the 10px lift never uncovers the bottom edge.
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: background),
        content,
      ],
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
