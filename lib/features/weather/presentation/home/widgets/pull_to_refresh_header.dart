import 'package:flutter/material.dart';

import '../../../../../core/theme/weather_icons.dart';

/// The "Pull to refresh" affordance under the location bar.
///
/// The design animates it with `bounceIcon` while refreshing; here the
/// platform `RefreshIndicator` owns the gesture, so this is the resting hint
/// that spins while a refresh is in flight.
class PullToRefreshHeader extends StatelessWidget {
  const PullToRefreshHeader({
    super.key,
    required this.color,
    this.refreshing = false,
  });

  final Color color;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pull down to refresh the forecast',
      child: Column(
        spacing: 2,
        children: [
          _BouncingIcon(active: refreshing, color: color),
          Text(
            refreshing ? 'Refreshing…' : 'Pull to refresh',
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

/// `@keyframes bounceIcon` — a squash-and-stretch hop, played once per
/// refresh.
class _BouncingIcon extends StatefulWidget {
  const _BouncingIcon({required this.active, required this.color});

  final bool active;
  final Color color;

  @override
  State<_BouncingIcon> createState() => _BouncingIconState();
}

class _BouncingIconState extends State<_BouncingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  late final Animation<double> _lift = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 30),
    TweenSequenceItem(tween: Tween(begin: -10, end: 2), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 2, end: -4), weight: 20),
    TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 25),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.94), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.02), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 25),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didUpdateWidget(_BouncingIcon old) {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _lift.value),
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: Icon(WeatherIcons.refresh, size: 20, color: widget.color),
    );
  }
}
