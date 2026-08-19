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

    return AnimatedSize(
      duration: _HourChip._duration,
      curve: _HourChip._curve,
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
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
                  temperature: formatter.temperature(
                    widget.hours[i].temperature,
                  ),
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
      ),
    );
  }
}

class _HourChip extends StatelessWidget {
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

  /// `transition:all .35s cubic-bezier(.34,1.56,.64,1)` on the chip.
  static const Duration _duration = Duration(milliseconds: 350);
  static const Curve _curve = Motion.tabBounceCurve;

  @override
  Widget build(BuildContext context) {
    final dark = palette.cardIsDark;

    return Semantics(
      button: true,
      expanded: expanded,
      label: '$label, $temperature, $precipitation',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: expanded ? 1.06 : 1,
          duration: _duration,
          curve: _curve,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AtmosTokens.radiusLg),
              boxShadow: expanded ? AtmosTokens.shadowMd : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AtmosTokens.radiusLg),
              child: BackdropFilter(
                filter: GlassSurface.glassFilter(dark: dark),
                child: AnimatedContainer(
                  duration: _duration,
                  curve: _curve,
                  constraints: const BoxConstraints(minWidth: 64),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    // Both recipes lift a little when the chip is open.
                    color: Colors.white.withValues(
                      alpha: dark
                          ? (expanded ? 0.16 : 0.08)
                          : (expanded ? 0.65 : 0.42),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: dark
                            ? (expanded ? 0.28 : 0.16)
                            : (expanded ? 0.7 : 0.5),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(AtmosTokens.radiusLg),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.cardSubText,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Icon(
                          icon,
                          size: 22,
                          color: palette.cardAccent,
                        ),
                      ),
                      Text(
                        temperature,
                        style: TextStyle(fontSize: 15, color: palette.cardText),
                      ),
                      if (expanded)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            precipitation,
                            style: TextStyle(
                              fontSize: 10,
                              color: palette.cardAccent2,
                            ),
                          ),
                        ),
                    ],
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
