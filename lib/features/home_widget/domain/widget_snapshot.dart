import '../../settings/application/unit_formatter.dart';
import '../../weather/domain/forecast.dart';
import '../../weather/domain/weather_condition.dart';
import 'sky_time.dart';

/// Everything the home-screen widgets draw, already formatted.
///
/// The widget extensions are separate processes with no access to the app's
/// settings or its locale plumbing, so the numbers cross the boundary as the
/// strings they will be printed as. Only the condition crosses as an
/// identifier, because the widget draws with it.
///
/// The time of day is the exception, and deliberately so. A widget shows the
/// last reading the app fetched, which can be hours old — so anything resolved
/// against "now" at publish time is wrong by the time it is read. The clock and
/// the sky therefore cross as *ingredients*: the place's UTC offset, and the
/// whole run of sky changes ahead. The widget resolves them itself, for the
/// moment it is actually drawing, and keeps moving through the day without the
/// app.
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.condition,
    required this.temperature,
    required this.humidity,
    required this.place,
    required this.utcOffset,
    required this.skySchedule,
    required this.updatedAt,
  });

  factory WidgetSnapshot.of(Forecast forecast, UnitFormatter formatter) {
    final now = forecast.localNow;

    return WidgetSnapshot(
      condition: forecast.current.condition,
      temperature: formatter.temperature(forecast.current.temperature),
      humidity: formatter.humidity(forecast.current.humidity),
      place: forecast.place.name,
      utcOffset: forecast.utcOffset,
      skySchedule: SkyTime.scheduleFrom(
        start: now,
        // Comfortably longer than any refresh gap worth drawing through. Past
        // this the widget holds the last sky, which is the old behaviour.
        window: scheduleWindow,
        days: [
          for (final day in forecast.daily)
            SunDay(sunrise: day.sunrise, sunset: day.sunset),
        ],
      ),
      updatedAt: now,
    );
  }

  /// How far ahead [skySchedule] runs.
  static const scheduleWindow = Duration(hours: 36);

  final WeatherCondition condition;

  /// "22°", already in the user's unit.
  final String temperature;

  /// "58%".
  final String humidity;

  final String place;

  /// The place's offset from UTC.
  ///
  /// Crosses twice over: it turns the API's naive wall-clock stamps into the
  /// absolute instants that cross (see [toStore]), and it goes over itself so
  /// the widget can print the reading's hour on the place's own clock.
  final Duration utcOffset;

  /// Every sky change from now to [scheduleWindow] out, in order.
  final List<SkyChange> skySchedule;

  /// When the reading was taken, so the widget can say how old it is.
  final DateTime updatedAt;

  /// The keys the native side reads. Flat strings, because that is all the
  /// shared stores on either platform hold.
  ///
  /// Every instant crosses as seconds since the epoch, UTC. The API's stamps
  /// are naive wall-clock readings of the *place*, so they are pulled back
  /// through [utcOffset] first — otherwise a phone in another zone would
  /// compare them against its own clock and land hours out.
  Map<String, String> toStore() => {
    'condition': condition.name,
    'conditionLabel': condition.label,
    'temperature': temperature,
    'humidity': humidity,
    'place': place,
    'utcOffsetMinutes': utcOffset.inMinutes.toString(),
    'skySchedule': [
      for (final change in skySchedule)
        '${_epochSeconds(change.at)}:${change.sky.name}',
    ].join(','),
    'updatedAt': _epochSeconds(updatedAt).toString(),
  };

  /// A naive wall-clock reading of the place, as an absolute instant.
  int _epochSeconds(DateTime wallClock) {
    final asUtc = DateTime.utc(
      wallClock.year,
      wallClock.month,
      wallClock.day,
      wallClock.hour,
      wallClock.minute,
      wallClock.second,
    );
    return asUtc.subtract(utcOffset).millisecondsSinceEpoch ~/ 1000;
  }
}
