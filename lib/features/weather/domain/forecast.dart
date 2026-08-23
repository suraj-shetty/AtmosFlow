import 'package:freezed_annotation/freezed_annotation.dart';

import 'place.dart';
import 'weather_condition.dart';

part 'forecast.freezed.dart';

/// Everything the Home and Day Detail screens need for one place.
///
/// All temperatures are Celsius and all wind speeds km/h — the canonical units
/// the app requests from the API. Display conversion happens at the edge, in
/// `UnitFormatter`, never in the domain.
@freezed
abstract class Forecast with _$Forecast {
  const factory Forecast({
    required Place place,
    required CurrentWeather current,
    required List<HourlyPoint> hourly,
    required List<DailyForecast> daily,
    required DateTime fetchedAt,

    /// The place's offset from UTC, as the API reported it.
    required Duration utcOffset,
  }) = _Forecast;

  const Forecast._();

  /// "Now" where the forecast is, as a naive wall-clock `DateTime`.
  ///
  /// Open-Meteo returns local wall-clock stamps with no zone suffix, so they
  /// parse as device-local. Comparing those against a UTC-flagged instant
  /// compares absolute time and lands the wrong hour whenever the place and
  /// the device are in different zones — this rebuilds the place's clock in
  /// the same naive shape so the two compare wall-clock to wall-clock.
  DateTime get localNow => wallClockNow(utcOffset);

  /// The app's source of "now".
  ///
  /// A seam rather than an abstraction: the sun-path dot tracks this minute
  /// by minute, which is exactly the kind of drift that makes a golden pass
  /// at 3:00 and fail at 3:01.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  static DateTime wallClockNow(Duration utcOffset) {
    final wall = clock().toUtc().add(utcOffset);
    return DateTime(
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
      wall.second,
    );
  }

  /// How long ago this reading was taken.
  ///
  /// Lives here rather than at the call site because [clock] is the app's
  /// test seam and belongs to the domain — and because "how old is this" is
  /// a question about a forecast, not about whoever is asking.
  Duration get age => clock().difference(fetchedAt);

  /// The next 24 entries from now — what the Home strip scrolls through.
  List<HourlyPoint> get next24Hours => hourly.take(24).toList(growable: false);

  DailyForecast? dayFor(DateTime date) {
    for (final day in daily) {
      if (day.date.year == date.year &&
          day.date.month == date.month &&
          day.date.day == date.day) {
        return day;
      }
    }
    return null;
  }
}

@freezed
abstract class CurrentWeather with _$CurrentWeather {
  const factory CurrentWeather({
    required double temperature,
    required double feelsLike,
    required WeatherCondition condition,
    required bool isNight,
    required int humidity,
    required double windSpeed,
    required int windDirection,
    required double uvIndex,
    required double visibilityMetres,
    required double pressureHpa,
  }) = _CurrentWeather;

  const CurrentWeather._();

  /// Compass point for the "Wind · NW" label.
  String get windCompass {
    const points = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', //
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
    ];
    return points[(((windDirection % 360) / 22.5).round()) % 16];
  }
}

/// The WHO exposure band for a UV index. Free functions rather than getters,
/// so a screen can band whichever value it is actually showing — Home reports
/// the current UV, Day Detail the day's maximum.
String uvBandOf(double uvIndex) => switch (uvIndex) {
  < 3 => 'Low',
  < 6 => 'Moderate',
  < 8 => 'High',
  < 11 => 'Very high',
  _ => 'Extreme',
};

/// How far along the 0–11+ scale a UV index sits.
double uvFractionOf(double uvIndex) => (uvIndex / 11).clamp(0.0, 1.0);

@freezed
abstract class HourlyPoint with _$HourlyPoint {
  const factory HourlyPoint({
    required DateTime time,
    required double temperature,
    required WeatherCondition condition,
    required bool isNight,
    required int precipitationProbability,
  }) = _HourlyPoint;
}

@freezed
abstract class DailyForecast with _$DailyForecast {
  const factory DailyForecast({
    required DateTime date,
    required double high,
    required double low,
    required WeatherCondition condition,
    required DateTime sunrise,
    required DateTime sunset,
    required double uvIndexMax,

    /// 24 hourly temperatures, midnight to 11PM — the Day Detail line chart.
    required List<double> hourlyTemperatures,
  }) = _DailyForecast;

  const DailyForecast._();

  /// How far through the daylight window [at] falls, 0–1. Drives the sun-path
  /// dot; clamped so a pre-dawn or post-dusk read parks it at either end.
  double sunProgressAt(DateTime at) {
    final span = sunset.difference(sunrise).inSeconds;
    if (span <= 0) return 0;
    final elapsed = at.difference(sunrise).inSeconds;
    return (elapsed / span).clamp(0.0, 1.0);
  }
}
