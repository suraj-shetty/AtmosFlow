import '../../settings/application/unit_formatter.dart';
import '../../weather/domain/forecast.dart';
import '../../weather/domain/weather_condition.dart';
import 'sky_time.dart';

/// Everything the home-screen widgets draw, already formatted.
///
/// The widget extensions are separate processes with no access to the app's
/// settings or its locale plumbing, so the numbers cross the boundary as the
/// strings they will be printed as. Only the two things the widget *draws*
/// with — the condition and the sky — cross as identifiers.
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.condition,
    required this.sky,
    required this.temperature,
    required this.humidity,
    required this.clock,
    required this.place,
    required this.updatedAt,
  });

  factory WidgetSnapshot.of(Forecast forecast, UnitFormatter formatter) {
    final now = forecast.localNow;
    final today = forecast.daily.first;

    return WidgetSnapshot(
      condition: forecast.current.condition,
      sky: SkyTime.resolve(
        now: now,
        sunrise: today.sunrise,
        sunset: today.sunset,
      ),
      temperature: formatter.temperature(forecast.current.temperature),
      humidity: formatter.humidity(forecast.current.humidity),
      clock: '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      place: forecast.place.name,
      updatedAt: now,
    );
  }

  final WeatherCondition condition;
  final SkyTime sky;

  /// "22°", already in the user's unit.
  final String temperature;

  /// "58%".
  final String humidity;

  /// "14:30" — the place's own clock, not the device's.
  final String clock;
  final String place;
  final DateTime updatedAt;

  /// "Afternoon · Clear", the caption under the temperature.
  String get caption => '${sky.label} · ${condition.label}';

  /// The keys the native side reads. Flat strings, because that is all the
  /// shared stores on either platform hold.
  Map<String, String> toStore() => {
    'condition': condition.name,
    'sky': sky.name,
    'temperature': temperature,
    'humidity': humidity,
    'clock': clock,
    'place': place,
    'caption': caption,
    'conditionLabel': condition.label,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
