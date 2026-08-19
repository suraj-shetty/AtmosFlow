import 'package:flutter/material.dart';

import '../../../../../core/theme/atmos_tokens.dart';
import '../../../../../core/theme/glass.dart';
import '../../../../../core/theme/weather_palette.dart';
import '../../../../../core/widgets/screen_transition.dart';

/// One cell of Home's 2×2 metric grid — icon, caption, value — on light
/// glass, rising into place with the staggered `fadeSlideUp`.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.palette,
    this.delay = Duration.zero,
  });

  final IconData icon;
  final String label;
  final String value;

  /// The sky behind the tile — decides the glass recipe and text colours.
  final WeatherPalette palette;

  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return FadeSlideUp(
      delay: delay,
      child: GlassSurface(
        dark: palette.cardIsDark,
        padding: const EdgeInsets.all(AtmosTokens.space3),
        child: Row(
          children: [
            Icon(icon, size: 18, color: palette.cardAccent2),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: palette.cardSubText),
                  ),
                  Text(
                    value,
                    style: TextStyle(fontSize: 16, color: palette.cardText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
