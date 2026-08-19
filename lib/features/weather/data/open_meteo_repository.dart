import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart' as geo;

import '../../../core/failure/app_failure.dart';
import '../domain/forecast.dart';
import '../domain/place.dart';
import '../domain/weather_repository.dart';
import 'wmo_mapper.dart';

/// Live data from [Open-Meteo](https://open-meteo.com) — free, keyless, no
/// signup. Everything is requested in canonical units (°C, km/h, metres, hPa)
/// and converted for display at the edge.
class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository(this._dio);

  final Dio _dio;

  static const String forecastUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String geocodingUrl =
      'https://geocoding-api.open-meteo.com/v1/search';

  static const List<String> _currentFields = [
    'temperature_2m',
    'apparent_temperature',
    'relative_humidity_2m',
    'weather_code',
    'wind_speed_10m',
    'wind_direction_10m',
    'visibility',
    'pressure_msl',
    'uv_index',
    'is_day',
  ];
  static const List<String> _hourlyFields = [
    'temperature_2m',
    'precipitation_probability',
    'weather_code',
    'is_day',
  ];
  static const List<String> _dailyFields = [
    'weather_code',
    'temperature_2m_max',
    'temperature_2m_min',
    'sunrise',
    'sunset',
    'uv_index_max',
  ];

  @override
  Future<Forecast> fetchForecast(Place place) async {
    final json = await _get(forecastUrl, {
      'latitude': place.latitude,
      'longitude': place.longitude,
      'current': _currentFields.join(','),
      'hourly': _hourlyFields.join(','),
      'daily': _dailyFields.join(','),
      'timezone': 'auto',
      'forecast_days': 7,
    });

    try {
      return _parseForecast(json, place);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw AppFailure.malformedResponse(detail: '$e');
    }
  }

  @override
  Future<List<Place>> searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final json = await _get(geocodingUrl, {
      'name': trimmed,
      'count': 10,
      'language': 'en',
      'format': 'json',
    });

    // Open-Meteo omits `results` entirely when nothing matches.
    final results = json['results'];
    if (results is! List) return const [];

    return [
      for (final r in results.cast<Map<String, Object?>>())
        Place(
          id: (r['id'] as num).toInt(),
          name: r['name'] as String,
          latitude: (r['latitude'] as num).toDouble(),
          longitude: (r['longitude'] as num).toDouble(),
          country: r['country'] as String?,
          admin1: r['admin1'] as String?,
          timezone: r['timezone'] as String?,
        ),
    ];
  }

  @override
  Future<Place> placeAt({
    required double latitude,
    required double longitude,
  }) async {
    // Open-Meteo has no reverse-geocoding endpoint, so the platform geocoder
    // names the coordinate. A failure here is cosmetic — fall back to a
    // generic label rather than denying the user their local forecast.
    String name = 'Current Location';
    String? country;
    String? admin1;
    try {
      final marks = await geo.Geocoding().placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (marks.isNotEmpty) {
        final m = marks.first;
        final candidates = <String?>[
          m.locality,
          m.subAdministrativeArea,
          m.administrativeArea,
        ];
        name =
            candidates.firstWhere(
              (v) => v != null && v.isNotEmpty,
              orElse: () => null,
            ) ??
            name;
        country = m.country;
        admin1 = m.administrativeArea;
      }
    } catch (_) {
      // Keep the fallback label.
    }

    return Place(
      id: Place.currentLocationId,
      name: name,
      latitude: latitude,
      longitude: longitude,
      country: country,
      admin1: admin1,
    );
  }

  Future<Map<String, Object?>> _get(
    String url,
    Map<String, Object?> query,
  ) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        url,
        queryParameters: query,
      );
      final data = response.data;
      if (data == null) throw const AppFailure.malformedResponse();
      if (data['error'] == true) {
        throw AppFailure.notFound(detail: data['reason'] as String?);
      }
      return data;
    } on DioException catch (e) {
      // The failure reaches the UI as friendly copy, which leaves nothing to
      // debug from when a request fails on device. Log the cause in debug
      // builds only.
      assert(() {
        debugPrint(
          'AtmosFlow: request to $url failed — ${e.type.name}: ${e.message}'
          '${e.response == null ? '' : ' (HTTP ${e.response!.statusCode})'}',
        );
        return true;
      }());

      throw switch (e.response?.statusCode) {
        404 => const AppFailure.notFound(),
        _ => AppFailure.network(detail: e.message),
      };
    }
  }

  // ── Parsing ─────────────────────────────────────────────────────────────

  Forecast _parseForecast(Map<String, Object?> json, Place place) {
    final offset = Duration(
      seconds: (json['utc_offset_seconds'] as num).toInt(),
    );
    final current = json['current']! as Map<String, Object?>;
    final hourly = json['hourly']! as Map<String, Object?>;
    final daily = json['daily']! as Map<String, Object?>;

    final hourlyTimes = _times(hourly['time']);
    final hourlyTemps = _doubles(hourly['temperature_2m']);
    final hourlyCodes = _ints(hourly['weather_code']);
    final hourlyIsDay = _ints(hourly['is_day']);
    final hourlyPrecip = _ints(hourly['precipitation_probability']);

    // The API returns the whole day from midnight; the strip starts at the
    // hour containing "now" in the location's own time. Both sides of this
    // comparison have to be naive wall-clock, or a place in another zone
    // starts the strip at the wrong hour.
    final localNow = Forecast.wallClockNow(offset);
    var startIndex = hourlyTimes.indexWhere((t) => !t.isBefore(localNow));
    if (startIndex > 0) startIndex -= 1; // include the current hour
    if (startIndex < 0) startIndex = 0;

    final points = <HourlyPoint>[
      for (var i = startIndex; i < hourlyTimes.length; i++)
        HourlyPoint(
          time: hourlyTimes[i],
          temperature: hourlyTemps[i],
          condition: WmoCodeMapper.toCondition(hourlyCodes[i]),
          isNight: hourlyIsDay[i] == 0,
          precipitationProbability: hourlyPrecip[i],
        ),
    ];

    final dayDates = _times(daily['time']);
    final dayCodes = _ints(daily['weather_code']);
    final dayMax = _doubles(daily['temperature_2m_max']);
    final dayMin = _doubles(daily['temperature_2m_min']);
    final sunrises = _times(daily['sunrise']);
    final sunsets = _times(daily['sunset']);
    final uvMax = _doubles(daily['uv_index_max']);

    final days = <DailyForecast>[
      for (var i = 0; i < dayDates.length; i++)
        DailyForecast(
          date: dayDates[i],
          high: dayMax[i],
          low: dayMin[i],
          condition: WmoCodeMapper.toCondition(dayCodes[i]),
          sunrise: sunrises[i],
          sunset: sunsets[i],
          uvIndexMax: uvMax[i],
          hourlyTemperatures: _temperaturesForDay(
            dayDates[i],
            hourlyTimes,
            hourlyTemps,
          ),
        ),
    ];

    return Forecast(
      place: place,
      current: CurrentWeather(
        temperature: (current['temperature_2m']! as num).toDouble(),
        feelsLike: (current['apparent_temperature']! as num).toDouble(),
        condition: WmoCodeMapper.toCondition(
          (current['weather_code']! as num).toInt(),
        ),
        isNight: (current['is_day']! as num).toInt() == 0,
        humidity: (current['relative_humidity_2m']! as num).round(),
        windSpeed: (current['wind_speed_10m']! as num).toDouble(),
        windDirection: (current['wind_direction_10m']! as num).round(),
        uvIndex: (current['uv_index'] as num?)?.toDouble() ?? 0,
        visibilityMetres: (current['visibility'] as num?)?.toDouble() ?? 0,
        pressureHpa: (current['pressure_msl']! as num).toDouble(),
      ),
      hourly: points,
      daily: days,
      fetchedAt: DateTime.now(),
      utcOffset: offset,
    );
  }

  /// The 24 hourly temperatures belonging to one calendar day, which is what
  /// the Day Detail chart plots. Days at the edge of the window can be short;
  /// the chart handles any length.
  static List<double> _temperaturesForDay(
    DateTime day,
    List<DateTime> times,
    List<double> temps,
  ) {
    final out = <double>[];
    for (var i = 0; i < times.length; i++) {
      final t = times[i];
      if (t.year == day.year && t.month == day.month && t.day == day.day) {
        out.add(temps[i]);
      }
    }
    return out;
  }

  /// Open-Meteo emits local wall-clock ISO strings with no zone suffix, so
  /// these parse as "local" and are only ever compared against each other.
  static List<DateTime> _times(Object? raw) =>
      (raw! as List).cast<String>().map(DateTime.parse).toList(growable: false);

  static List<double> _doubles(Object? raw) => (raw! as List)
      .map((v) => (v as num?)?.toDouble() ?? 0)
      .toList(growable: false);

  static List<int> _ints(Object? raw) => (raw! as List)
      .map((v) => (v as num?)?.toInt() ?? 0)
      .toList(growable: false);
}
