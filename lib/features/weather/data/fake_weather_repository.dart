import '../../../core/failure/app_failure.dart';
import '../domain/forecast.dart';
import '../domain/place.dart';
import '../domain/weather_condition.dart';
import '../domain/weather_repository.dart';

/// The design prototype's own fixture data, verbatim: the six seeded
/// locations, the four extra search hits, the 8-entry hourly strip, the 7-day
/// list and the 24-point temperature curve.
///
/// Used by widget tests, goldens and offline development — anywhere a
/// deterministic forecast beats a live one.
class FakeWeatherRepository implements WeatherRepository {
  FakeWeatherRepository({
    DateTime? now,
    this.latency = Duration.zero,
    this.failWith,
  }) : _now = now ?? DateTime(2026, 8, 19, 12);

  final DateTime _now;
  final Duration latency;

  /// When set, every call throws this instead — for exercising error states.
  final AppFailure? failWith;

  /// `LOCATIONS` in the prototype.
  static const List<Place> savedFixtures = [
    Place(
      id: 1,
      name: 'San Francisco',
      latitude: 37.7749,
      longitude: -122.4194,
      country: 'United States',
      admin1: 'California',
    ),
    Place(
      id: 2,
      name: 'Tokyo',
      latitude: 35.6895,
      longitude: 139.6917,
      country: 'Japan',
      admin1: 'Tokyo',
    ),
    Place(
      id: 3,
      name: 'Reykjavík',
      latitude: 64.1466,
      longitude: -21.9426,
      country: 'Iceland',
    ),
    Place(
      id: 4,
      name: 'Marrakech',
      latitude: 31.6295,
      longitude: -7.9811,
      country: 'Morocco',
    ),
    Place(
      id: 5,
      name: 'London',
      latitude: 51.5072,
      longitude: -0.1276,
      country: 'United Kingdom',
      admin1: 'England',
    ),
    Place(
      id: 6,
      name: 'Denver',
      latitude: 39.7392,
      longitude: -104.9903,
      country: 'United States',
      admin1: 'Colorado',
    ),
  ];

  /// `SEARCH_EXTRA` — only reachable through search, never pre-saved.
  static const List<Place> searchOnlyFixtures = [
    Place(
      id: 7,
      name: 'Paris',
      latitude: 48.8566,
      longitude: 2.3522,
      country: 'France',
    ),
    Place(
      id: 8,
      name: 'Cairo',
      latitude: 30.0444,
      longitude: 31.2357,
      country: 'Egypt',
    ),
    Place(
      id: 9,
      name: 'Mumbai',
      latitude: 19.0760,
      longitude: 72.8777,
      country: 'India',
    ),
    Place(
      id: 10,
      name: 'Oslo',
      latitude: 59.9139,
      longitude: 10.7522,
      country: 'Norway',
    ),
  ];

  /// Each fixture location's temperature and condition, as the prototype's
  /// saved-location rows show them.
  static const Map<int, (double, WeatherCondition)> _conditionsById = {
    1: (22, WeatherCondition.clear),
    2: (24, WeatherCondition.rain),
    3: (2, WeatherCondition.snow),
    4: (31, WeatherCondition.clear),
    5: (16, WeatherCondition.cloudy),
    6: (14, WeatherCondition.storm),
    7: (18, WeatherCondition.cloudy),
    8: (34, WeatherCondition.clear),
    9: (29, WeatherCondition.rain),
    10: (5, WeatherCondition.snow),
  };

  /// `HOURLY` — (hour offset from now, temp, condition, precip %).
  static const List<(int, double, WeatherCondition, int)> _hourlyFixture = [
    (0, 22, WeatherCondition.clear, 5),
    (1, 23, WeatherCondition.clear, 0),
    (2, 23, WeatherCondition.clear, 0),
    (3, 22, WeatherCondition.cloudy, 10),
    (4, 21, WeatherCondition.cloudy, 15),
    (5, 20, WeatherCondition.cloudy, 20),
    (6, 19, WeatherCondition.clear, 5),
    (7, 18, WeatherCondition.clear, 0),
  ];

  /// `DAILY` — (day offset, high, low, condition).
  static const List<(int, double, double, WeatherCondition)> _dailyFixture = [
    (0, 23, 16, WeatherCondition.clear),
    (1, 22, 15, WeatherCondition.cloudy),
    (2, 19, 14, WeatherCondition.rain),
    (3, 20, 14, WeatherCondition.cloudy),
    (4, 24, 16, WeatherCondition.clear),
    (5, 25, 17, WeatherCondition.clear),
    (6, 21, 15, WeatherCondition.storm),
  ];

  /// `GRAPH_TEMPS` — the 24-point curve the Day Detail chart draws.
  static const List<double> graphTemperatures = [
    16, 15, 15, 16, 18, 20, 22, 23, 24, 23, 22, 21, //
    20, 19, 19, 18, 18, 17, 17, 16, 16, 16, 15, 15,
  ];

  @override
  Future<Forecast> fetchForecast(Place place) async {
    await _settle();
    final (temp, condition) =
        _conditionsById[place.id] ?? (22.0, WeatherCondition.clear);
    final isNight = _now.hour < 6 || _now.hour >= 20;
    final today = DateTime(_now.year, _now.month, _now.day);

    return Forecast(
      place: place,
      current: CurrentWeather(
        temperature: temp,
        feelsLike: temp - 2,
        condition: condition,
        isNight: isNight,
        humidity: 58,
        windSpeed: 12,
        windDirection: 315, // NW, matching the design's wind arrow
        uvIndex: 5,
        visibilityMetres: 12000,
        pressureHpa: 1015,
      ),
      hourly: [
        for (final (offset, t, c, precip) in _hourlyFixture)
          HourlyPoint(
            time: _now.add(Duration(hours: offset)),
            temperature: t,
            condition: c,
            isNight:
                (_now.hour + offset) % 24 >= 20 ||
                (_now.hour + offset) % 24 < 6,
            precipitationProbability: precip,
          ),
      ],
      daily: [
        for (final (offset, hi, lo, c) in _dailyFixture)
          DailyForecast(
            date: today.add(Duration(days: offset)),
            high: hi,
            low: lo,
            condition: c,
            sunrise: today.add(Duration(days: offset, hours: 6, minutes: 10)),
            sunset: today.add(Duration(days: offset, hours: 20, minutes: 5)),
            uvIndexMax: 5,
            hourlyTemperatures: graphTemperatures,
          ),
      ],
      fetchedAt: _now,
      utcOffset: Duration.zero,
    );
  }

  @override
  Future<List<Place>> searchPlaces(String query) async {
    await _settle();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return [
      ...savedFixtures,
      ...searchOnlyFixtures,
    ].where((p) => p.name.toLowerCase().contains(q)).toList(growable: false);
  }

  @override
  Future<Place> placeAt({
    required double latitude,
    required double longitude,
  }) async {
    await _settle();
    return savedFixtures.first.copyWith(
      id: Place.currentLocationId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> _settle() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (failWith != null) throw failWith!;
  }
}
