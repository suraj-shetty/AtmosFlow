import '../domain/weather_condition.dart';

/// Collapses WMO 4677 weather codes — what Open-Meteo returns — into the seven
/// conditions the design draws.
///
/// The design has no separate "partly cloudy" or "freezing rain" sky, so
/// neighbouring codes fold into the nearest one that does exist: freezing
/// drizzle joins drizzle, freezing rain and showers join rain, snow grains and
/// snow showers join snow.
abstract final class WmoCodeMapper {
  static WeatherCondition toCondition(int code) => switch (code) {
    0 || 1 => WeatherCondition.clear, // clear, mainly clear
    2 || 3 => WeatherCondition.cloudy, // partly cloudy, overcast
    45 || 48 => WeatherCondition.fog, // fog, depositing rime fog
    51 || 53 || 55 => WeatherCondition.drizzle, // drizzle
    56 || 57 => WeatherCondition.drizzle, // freezing drizzle
    61 || 63 || 65 => WeatherCondition.rain, // rain
    66 || 67 => WeatherCondition.rain, // freezing rain
    71 || 73 || 75 => WeatherCondition.snow, // snowfall
    77 => WeatherCondition.snow, // snow grains
    80 || 81 || 82 => WeatherCondition.rain, // rain showers
    85 || 86 => WeatherCondition.snow, // snow showers
    95 || 96 || 99 => WeatherCondition.storm, // thunderstorm
    // Anything unmapped reads as overcast rather than as an error — a sky the
    // user can look at beats an error state for a code we don't recognise.
    _ => WeatherCondition.cloudy,
  };
}
