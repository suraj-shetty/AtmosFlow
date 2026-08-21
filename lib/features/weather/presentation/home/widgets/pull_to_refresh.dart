import 'package:flutter/material.dart';

import '../../../../../core/theme/motion.dart';

/// Turns a drag past the top of [child] into a 0–1 pull value, and a release
/// past the trigger into one refresh.
///
/// Replaces `RefreshIndicator`, which owns its own gesture *and* its own
/// spinner: the design wants the app's puck instead, and the stock indicator
/// gives no way to read how far the finger has travelled — which is exactly
/// what the bubble is drawn from. The scrollable is given bouncing physics on
/// every platform so the overscroll this reads exists on Android too.
class PullToRefresh extends StatefulWidget {
  const PullToRefresh({
    super.key,
    required this.pull,
    required this.refreshing,
    required this.onRefresh,
    required this.child,
  });

  /// Written on every drag frame: 0 at rest, 1 at the trigger, and a little
  /// past it while the finger keeps going.
  final ValueNotifier<double> pull;

  /// Whether a refresh is already running — a second pull is ignored.
  final bool refreshing;

  final Future<void> Function() onRefresh;
  final Widget child;

  /// The physics the scrollable inside a [PullToRefresh] wants.
  static const ScrollPhysics physics = AlwaysScrollableScrollPhysics(
    parent: BouncingScrollPhysics(),
  );

  @override
  State<PullToRefresh> createState() => _PullToRefreshState();
}

class _PullToRefreshState extends State<PullToRefresh> {
  /// Whether the last position change came from a finger. A scrollable
  /// dispatches nothing at the moment a drag ends — it simply carries on
  /// updating, ballistically, with no drag attached — so the first update
  /// without one is the release, and the last pull value before it is how far
  /// the finger actually got.
  bool _dragging = false;

  bool _onNotification(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }

    if (notification is ScrollStartNotification) {
      _dragging = notification.dragDetails != null;
    } else if (notification is ScrollEndNotification) {
      _dragging = false;
      widget.pull.value = 0;
    } else if (notification is ScrollUpdateNotification ||
        notification is OverscrollNotification) {
      final dragging = notification is ScrollUpdateNotification
          ? notification.dragDetails != null
          : (notification as OverscrollNotification).dragDetails != null;

      if (!dragging && _dragging) {
        _dragging = false;
        if (widget.pull.value >= 1 && !widget.refreshing) widget.onRefresh();
      } else if (dragging) {
        _dragging = true;
      }

      // Updated after the release check, so the spring back does not undo the
      // travel the finger had already earned.
      final overscroll = -notification.metrics.pixels;
      widget.pull.value = overscroll <= 0
          ? 0
          : (overscroll / Motion.pullTrigger).clamp(0.0, 1.35);
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: widget.child,
    );
  }
}
