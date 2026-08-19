import 'forecast.dart';
import 'place.dart';

/// The one seam between the app and where weather comes from.
///
/// Two implementations ship: `OpenMeteoWeatherRepository` (live) and
/// `FakeWeatherRepository` (the design's own fixtures — used by tests, goldens
/// and offline development).
///
/// Implementations throw `AppFailure` and nothing else.
abstract interface class WeatherRepository {
  /// Full forecast for a place: current conditions, hourly, and 7 days.
  Future<Forecast> fetchForecast(Place place);

  /// Geocoding search for the Search screen. Returns [] for a blank query.
  Future<List<Place>> searchPlaces(String query);

  /// Reverse-geocodes a coordinate into a named place.
  Future<Place> placeAt({required double latitude, required double longitude});
}
