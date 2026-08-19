import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/atmos_tokens.dart';
import '../../../../../core/theme/glass.dart';
import '../../../../../core/theme/weather_icons.dart';
import '../../../../../core/theme/weather_palette.dart';
import '../../../../settings/application/settings_providers.dart';
import '../../../domain/forecast.dart';

/// "Next 24 hours" — a horizontal strip of glass chips. Tapping one expands it
/// to reveal its precipitation chance, and collapses whichever was open.
class HourlyStrip extends ConsumerStatefulWidget {
  const HourlyStrip({super.key, required this.hours, required this.palette});

  final List<HourlyPoint> hours;

  /// The sky the chips sit on — decides the glass recipe and text colours.
  final WeatherPalette palette;

  @override
  ConsumerState<HourlyStrip> createState() => _HourlyStripState();
}

class _HourlyStripState extends ConsumerState<HourlyStrip> {
  int? _expanded;

  @override
  Widget build(BuildContext context) {
    final formatter = ref.watch(unitFormatterProvider);

    return SizedBox(
      // Tall enough for an expanded chip's extra line, so the strip itself
      // never resizes — only the chip inside it grows.
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 6),
        clipBehavior: Clip.none,
        itemCount: widget.hours.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final hour = widget.hours[index];
          final isExpanded = _expanded == index;
          final label = index == 0 ? 'Now' : DateFormat('ha').format(hour.time);

          // A horizontal ListView hands its children the full viewport
          // height; aligning to the top lets a chip hug its own content
          // instead of stretching into a capsule.
          return Align(
            alignment: Alignment.topCenter,
            child: _HourChip(
              label: label,
              temperature: formatter.temperature(hour.temperature),
              icon: WeatherIcons.forCondition(
                hour.condition,
                isNight: hour.isNight,
              ),
              precipitation: '${hour.precipitationProbability}%',
              expanded: isExpanded,
              onTap: () =>
                  setState(() => _expanded = isExpanded ? null : index),
              palette: widget.palette,
            ),
          );
        },
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

  /// Every chip keeps this width whether open or closed. Growing the width
  /// would shove every chip to its right sideways — the reflow, not the
  /// reveal, is what made the old animation read as a glitch.
  static const double _width = 72;

  static const Duration _duration = Duration(milliseconds: 260);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final isDark = palette.cardIsDark;

    return Semantics(
      button: true,
      expanded: expanded,
      label: '$label, $temperature, $precipitation chance of rain',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _width,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AtmosTokens.radiusLg),
            child: BackdropFilter(
              filter: GlassSurface.glassFilter(dark: isDark),
              child: AnimatedContainer(
                duration: _duration,
                curve: _curve,
                padding: const EdgeInsets.symmetric(
                  vertical: AtmosTokens.space2,
                  horizontal: AtmosTokens.space1,
                ),
                decoration: BoxDecoration(
                  // The open chip lifts out of the row by tinting up rather
                  // than by changing size.
                  color: Colors.white.withValues(
                    alpha: isDark
                        ? (expanded ? 0.18 : 0.08)
                        : (expanded ? 0.62 : 0.42),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: isDark
                          ? (expanded ? 0.32 : 0.16)
                          : (expanded ? 0.75 : 0.55),
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
                      child: Icon(icon, size: 20, color: palette.cardAccent),
                    ),
                    Text(
                      temperature,
                      style: TextStyle(fontSize: 15, color: palette.cardText),
                    ),
                    // The precipitation line unrolls and fades in together,
                    // so the chip grows into it instead of the text popping.
                    AnimatedSize(
                      duration: _duration,
                      curve: _curve,
                      alignment: Alignment.topCenter,
                      child: AnimatedOpacity(
                        opacity: expanded ? 1 : 0,
                        duration: _duration,
                        curve: _curve,
                        child: expanded
                            ? _PrecipitationLine(
                                value: precipitation,
                                color: palette.cardAccent2,
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrecipitationLine extends StatelessWidget {
  const _PrecipitationLine({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(WeatherIcons.humidity, size: 10, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 10, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
