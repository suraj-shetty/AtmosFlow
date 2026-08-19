import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/glass.dart';
import '../../../../../core/theme/weather_icons.dart';
import '../../../../../core/theme/weather_palette.dart';
import '../../../domain/forecast.dart';

/// One row of the 7-day forecast: day name, condition icon, low, high,
/// chevron. Tapping it opens Day Detail.
///
/// Glass and copy follow the sky, the way the design's own Day Detail panels
/// do — a light row with ink text would be unreadable at night.
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
  final WeatherPalette palette;

  @override
  Widget build(BuildContext context) {
    final name = isToday ? 'Today' : DateFormat('E').format(day.date);

    return GlassSurface.forSky(
      isDark: palette.cardIsDark,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
          Icon(
            WeatherIcons.chevronRight,
            size: 16,
            color: palette.cardFaintText,
          ),
        ],
      ),
    );
  }
}
