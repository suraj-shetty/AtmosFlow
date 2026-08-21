import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/atmos_tokens.dart';
import '../../../../../core/theme/glass.dart';
import '../../../../../core/theme/motion.dart';
import '../../../../../core/theme/weather_icons.dart';
import '../../../../../core/widgets/screen_transition.dart';
import '../../../../settings/application/settings_providers.dart';
import '../../../../../core/theme/weather_palette.dart';
import '../../../domain/forecast.dart';

/// "Next 24 hours" — a horizontal strip of glass chips. Tapping one expands it
/// to reveal its precipitation chance, and collapses whichever was open.
class HourlyStrip extends ConsumerStatefulWidget {
  const HourlyStrip({super.key, required this.hours, required this.palette});

  final List<HourlyPoint> hours;
  final WeatherPalette palette;

  @override
  ConsumerState<HourlyStrip> createState() => _HourlyStripState();
}

class _HourlyStripState extends ConsumerState<HourlyStrip> {
  int? _expanded;

  @override
  Widget build(BuildContext context) {
    final formatter = ref.watch(unitFormatterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.none,
      child: Row(
        // The chips hang from the top, so an expanded one grows downwards
        // instead of pushing its neighbours around.
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          for (var i = 0; i < widget.hours.length; i++)
            FadeSlideUp(
              delay: Motion.metricStagger * i,
              child: _HourChip(
                label: i == 0
                    ? 'Now'
                    : DateFormat('ha').format(widget.hours[i].time),
                temperature: formatter.temperature(widget.hours[i].temperature),
                icon: WeatherIcons.forCondition(
                  widget.hours[i].condition,
                  isNight: widget.hours[i].isNight,
                ),
                precipitation:
                    '${widget.hours[i].precipitationProbability}% precip',
                expanded: _expanded == i,
                onTap: () =>
                    setState(() => _expanded = _expanded == i ? null : i),
                palette: widget.palette,
              ),
            ),
        ],
      ),
    );
  }
}

/// One hour, open or closed.
///
/// Everything the tap changes — the chip's height, its corner radius, its
/// scale, its fill, its border and its shadow — is read off a single
/// controller, so the whole chip moves as one shape instead of a stack of
/// independently timed transitions. That is also why the precipitation line
/// is always built and revealed by a height factor: an `if (expanded)` child
/// appears at full size on the first frame and the growth snaps.
class _HourChip extends StatefulWidget {
  const _HourChip({
    required this.label,
    required this.temperature,
    required this.icon,
    required this.precipitation,
    required this.expanded,
    required this.onTap,
    required this.palette,
  });

  final String label;
  final String temperature;
  final IconData icon;
  final String precipitation;
  final bool expanded;
  final VoidCallback onTap;
  final WeatherPalette palette;

  @override
  State<_HourChip> createState() => _HourChipState();
}

class _HourChipState extends State<_HourChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.expanded ? 1 : 0,
    duration: Motion.hourExpand,
    reverseDuration: Motion.hourCollapse,
  );

  late final CurvedAnimation _open = CurvedAnimation(
    parent: _controller,
    curve: Motion.hourExpandCurve,
    reverseCurve: Motion.hourCollapseCurve.flipped,
  );

  @override
  void didUpdateWidget(_HourChip old) {
    super.didUpdateWidget(old);
    if (widget.expanded == old.expanded) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = widget.expanded ? 1 : 0;
    } else if (widget.expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _open.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.palette.cardIsDark;

    return Semantics(
      button: true,
      expanded: widget.expanded,
      label: '${widget.label}, ${widget.temperature}, ${widget.precipitation}',
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _open,
          builder: (context, child) {
            // The opening curve overshoots past 1; the shape properties ride
            // the overshoot, the reveal is clamped so the text never grows
            // taller than the space it will settle into.
            final t = _open.value;
            final reveal = t.clamp(0.0, 1.0);
            final radius = BorderRadius.circular(
              Motion.hourRadiusClosed +
                  (Motion.hourRadiusOpen - Motion.hourRadiusClosed) * t,
            );

            return Transform.scale(
              scale: 1 + 0.06 * t,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    for (final shadow in AtmosTokens.shadowMd)
                      BoxShadow(
                        color: shadow.color.withValues(
                          alpha: shadow.color.a * reveal,
                        ),
                        offset: shadow.offset,
                        blurRadius: shadow.blurRadius,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: BackdropFilter.grouped(
                    filter: GlassSurface.glassFilter(dark: dark),
                    // A Container rather than a DecoratedBox: the border is
                    // part of the chip's box, and only Container reserves the
                    // hairline it draws.
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 64),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        // Both recipes lift a little when the chip is open.
                        color: Colors.white.withValues(
                          alpha: dark
                              ? 0.08 + 0.08 * reveal
                              : 0.42 + 0.23 * reveal,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: dark
                                ? 0.16 + 0.12 * reveal
                                : 0.5 + 0.2 * reveal,
                          ),
                        ),
                        borderRadius: radius,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  color: widget.palette.cardSubText,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: widget.palette.cardAccent,
                ),
              ),
              Text(
                widget.temperature,
                style: TextStyle(fontSize: 15, color: widget.palette.cardText),
              ),
              _Reveal(
                animation: _open,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    widget.precipitation,
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.palette.cardAccent2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grows a child in from nothing, clipped, fading in over the second half of
/// the travel so the line is never legible at a squashed size.
///
/// Both axes are scaled, not just the height: the precipitation line is wider
/// than the closed chip, and a reveal that only clipped vertically would keep
/// the chip stretched to the text's full width for the whole of the collapse
/// and then snap narrow on the last frame.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value.clamp(0.0, 1.0);
        if (t == 0) return const SizedBox.shrink();
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: t,
            widthFactor: t,
            child: Opacity(
              opacity: ((t - 0.35) / 0.65).clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
