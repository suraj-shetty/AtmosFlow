import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/atmos_tokens.dart';
import '../../../../../core/theme/glass.dart';
import '../../../../../core/theme/weather_icons.dart';
import '../../../../../core/theme/weather_palette.dart';
import '../../../domain/forecast.dart';

/// One row of the 7-day forecast: day name, condition icon, low, high,
/// chevron. Tapping it opens Day Detail.
class DailyRow extends StatelessWidget {
  const DailyRow({
    super.key,
    required this.day,
    required this.isToday,
    required this.lowLabel,
    required this.highLabel,
    required this.onTap,
    required this.palette,
  });

  final DailyForecast day;
  final bool isToday;
  final String lowLabel;
  final String highLabel;
  final VoidCallback onTap;

  /// The sky behind the row — decides the glass recipe and text colours.
  final WeatherPalette palette;

  @override
  Widget build(BuildContext context) {
    final name = isToday ? 'Today' : DateFormat('E').format(day.date);

    return GlassSurface(
      dark: palette.cardIsDark,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        vertical: AtmosTokens.space3,
        horizontal: AtmosTokens.space4,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              name,
              style: TextStyle(fontSize: 14, color: palette.cardText),
            ),
          ),
          Icon(
            WeatherIcons.forCondition(day.condition),
            size: 20,
            color: palette.cardAccent,
          ),
          const Spacer(),
          Text(
            lowLabel,
            style: TextStyle(fontSize: 13, color: palette.cardSubText),
          ),
          const SizedBox(width: 10),
          Text(
            highLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: palette.cardText,
            ),
          ),
          const SizedBox(width: 6),
          Icon(WeatherIcons.chevronRight, size: 16, color: palette.cardSubText),
        ],
      ),
    );
  }
}
