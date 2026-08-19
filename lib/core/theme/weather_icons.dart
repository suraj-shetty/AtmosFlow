import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../features/weather/domain/weather_condition.dart';

/// The design system specifies Lucide throughout. The prototype hand-drew its
/// own Lucide-shaped set because it had no icon font available; here the real
/// thing does the job.
abstract final class WeatherIcons {
  /// The icon for a condition, swapping in the moon for a clear night.
  static IconData forCondition(
    WeatherCondition condition, {
    bool isNight = false,
  }) {
    if (condition == WeatherCondition.clear) {
      return isNight ? LucideIcons.moonStar : LucideIcons.sun;
    }
    return switch (condition) {
      WeatherCondition.clear => LucideIcons.sun, // handled above
      WeatherCondition.cloudy => LucideIcons.cloud,
      WeatherCondition.fog => LucideIcons.cloudFog,
      WeatherCondition.drizzle => LucideIcons.cloudDrizzle,
      WeatherCondition.rain => LucideIcons.cloudRain,
      WeatherCondition.snow => LucideIcons.cloudSnow,
      WeatherCondition.storm => LucideIcons.cloudLightning,
    };
  }

  static const IconData pin = LucideIcons.mapPin;
  static const IconData search = LucideIcons.search;
  static const IconData refresh = LucideIcons.refreshCw;
  static const IconData humidity = LucideIcons.droplets;
  static const IconData wind = LucideIcons.wind;
  static const IconData uv = LucideIcons.sun;
  static const IconData visibility = LucideIcons.eye;
  static const IconData pressure = LucideIcons.gauge;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData delete = LucideIcons.trash2;
  static const IconData grip = LucideIcons.gripVertical;
  static const IconData home = LucideIcons.house;
  static const IconData settings = LucideIcons.slidersHorizontal;
  static const IconData windArrow = LucideIcons.arrowUp;
  static const IconData myLocation = LucideIcons.locateFixed;
}
