import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/atmos_tokens.dart';
import '../../../../../core/theme/glass.dart';
import '../../../../../core/theme/weather_icons.dart';
import '../../../domain/forecast.dart';

/// One row of the 7-day forecast: day name, condition icon, low, high,
/// chevron. Tapping it opens Day Detail.
///
/// The design draws these rows on the light glass recipe whatever the sky is
/// doing, with ink text and the terracotta icon — so the colours here come
/// from the tokens, not from the palette.
class DailyRow extends StatelessWidget {
  const DailyRow({
    super.key,
    required this.day,
    required this.isToday,
    required this.lowLabel,
    required this.highLabel,
    required this.onTap,
  });

  final DailyForecast day;
  final bool isToday;
  final String lowLabel;
  final String highLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final name = isToday ? 'Today' : DateFormat('E').format(day.date);

    return GlassSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              name,
              style: TextStyle(fontSize: 14, color: tokens.text),
            ),
          ),
          Icon(
            WeatherIcons.forCondition(day.condition),
            size: 20,
            color: tokens.accentRamp.s700,
          ),
          const Spacer(),
          Text(
            lowLabel,
            style: TextStyle(fontSize: 13, color: tokens.neutral.s600),
          ),
          const SizedBox(width: 10),
          Text(
            highLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: tokens.text,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            WeatherIcons.chevronRight,
            size: 16,
            color: tokens.neutral.s500,
          ),
        ],
      ),
    );
  }
}
