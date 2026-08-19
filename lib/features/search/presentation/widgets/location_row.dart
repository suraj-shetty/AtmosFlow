import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/atmos_tokens.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/theme/weather_icons.dart';
import '../../../settings/application/settings_providers.dart';
import '../../../weather/application/weather_providers.dart';
import '../../../weather/domain/place.dart';

/// A saved or searched location on light glass, showing its current
/// temperature once the forecast for it resolves.
///
/// The temperature is deliberately lazy: the row renders immediately and the
/// number fills in, rather than blocking the list on a fan-out of requests.
class LocationRow extends ConsumerWidget {
  const LocationRow({
    super.key,
    required this.place,
    this.onTap,
    this.onDelete,
    this.leading,
    this.trailing,
  });

  final Place place;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final forecast = ref.watch(forecastProvider(place));
    final formatter = ref.watch(unitFormatterProvider);

    final condition = forecast.value?.current;

    return GlassSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        vertical: AtmosTokens.space3,
        horizontal: AtmosTokens.space4,
      ),
      child: Row(
        spacing: 12,
        children: [
          if (leading != null) leading!,
          Icon(
            condition == null
                ? WeatherIcons.pin
                : WeatherIcons.forCondition(
                    condition.condition,
                    isNight: condition.isNight,
                  ),
            size: 18,
            color: tokens.accentRamp.s700,
          ),
          Expanded(
            // Geocoding happily returns ten places called "London"; without
            // the region they are indistinguishable in the list.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  place.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: tokens.text),
                ),
                if (place.subtitle.isNotEmpty)
                  Text(
                    place.subtitle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: tokens.neutral.s600,
                    ),
                  ),
              ],
            ),
          ),
          if (condition != null)
            Text(
              formatter.temperature(condition.temperature),
              style: TextStyle(fontSize: 14, color: tokens.text),
            ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: Icon(
                WeatherIcons.delete,
                size: 16,
                color: tokens.neutral.s500,
              ),
              tooltip: 'Remove ${place.name}',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
