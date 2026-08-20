import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/failure/app_failure.dart';
import '../../../core/persistence/preferences.dart';
import '../data/open_meteo_repository.dart';
import '../domain/forecast.dart';
import '../domain/place.dart';
import '../domain/weather_repository.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      responseType: ResponseType.json,
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

/// Swapped for `FakeWeatherRepository` in tests and goldens.
final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => OpenMeteoWeatherRepository(ref.watch(dioProvider)),
);

// ── Saved locations ────────────────────────────────────────────────────────

/// The user's locations, in their chosen order. Persisted on every mutation.
class SavedLocationsNotifier extends Notifier<List<Place>> {
  @override
  List<Place> build() {
    final raw = ref
        .read(sharedPreferencesProvider)
        .getStringList(PrefKeys.savedLocations);
    if (raw == null) return const [];
    try {
      return [
        for (final entry in raw)
          Place.fromJson(jsonDecode(entry) as Map<String, Object?>),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Adds a place unless it is already saved. Returns the place either way,
  /// so callers can select it without caring which happened.
  Place add(Place place) {
    if (!state.any((p) => p.id == place.id)) {
      _write([...state, place]);
    }
    return place;
  }

  void remove(int id) => _write([
    for (final p in state)
      if (p.id != id) p,
  ]);

  /// Drag-to-reorder. [newIndex] is the index the row lands on *after* it
  /// has been lifted out, which is what `onReorderItem` hands us — the older
  /// `onReorder` counted against the un-shortened list and left the
  /// off-by-one to the caller.
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final next = [...state];
    next.insert(newIndex, next.removeAt(oldIndex));
    _write(next);
  }

  void _write(List<Place> next) {
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(PrefKeys.savedLocations, [
      for (final p in next) jsonEncode(p.toJson()),
    ]);
  }
}

final savedLocationsProvider =
    NotifierProvider<SavedLocationsNotifier, List<Place>>(
      SavedLocationsNotifier.new,
    );

// ── Selection ──────────────────────────────────────────────────────────────

/// The place Home is showing. Null until onboarding resolves one.
class SelectedPlaceNotifier extends Notifier<Place?> {
  @override
  Place? build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final id = prefs.getInt(PrefKeys.selectedPlaceId);
    final saved = ref.watch(savedLocationsProvider);
    if (saved.isEmpty) return null;
    return saved.firstWhere((p) => p.id == id, orElse: () => saved.first);
  }

  void select(Place place) {
    state = place;
    ref
        .read(sharedPreferencesProvider)
        .setInt(PrefKeys.selectedPlaceId, place.id);
  }
}

final selectedPlaceProvider = NotifierProvider<SelectedPlaceNotifier, Place?>(
  SelectedPlaceNotifier.new,
);

// ── Forecast ───────────────────────────────────────────────────────────────

/// Forecast for one place. `ref.invalidate` on this is what pull-to-refresh
/// does.
final forecastProvider = FutureProvider.family<Forecast, Place>(
  (ref, place) {
    // Riverpod 3 auto-disposes by default; hold the response so switching tabs
    // or scrolling a list of saved places doesn't re-fetch. Pull-to-refresh
    // invalidates it explicitly.
    ref.keepAlive();
    return ref.watch(weatherRepositoryProvider).fetchForecast(place);
  },
  // Riverpod 3 retries failed providers on a backoff by default. The design
  // puts the user in charge instead — an error state with "Try again", and
  // pull-to-refresh — so a silent retry loop would only burn battery offline.
  retry: (_, _) => null,
);

/// The forecast Home shows — the selected place's, or nothing selected yet.
final currentForecastProvider = Provider<AsyncValue<Forecast>?>((ref) {
  final place = ref.watch(selectedPlaceProvider);
  if (place == null) return null;
  return ref.watch(forecastProvider(place));
});

// ── Search ─────────────────────────────────────────────────────────────────

/// Geocoding results for one query, debounced so a fast typist doesn't spray
/// requests.
///
/// The query is the family key rather than a provider of its own: what the
/// user has typed is state belonging to the Search screen, and a provider
/// holding it would outlive the screen — the field would come back still
/// carrying the last search, over stale results, and re-fetch them.
final placeSearchProvider = FutureProvider.autoDispose
    .family<List<Place>, String>((ref, rawQuery) async {
      final query = rawQuery.trim();
      if (query.isEmpty) return const [];

      // Debounce: a keystroke asks for a different family member, disposing
      // the previous one. Bailing out when it is no longer mounted is what
      // stops a fast typist from spraying requests.
      final repository = ref.watch(weatherRepositoryProvider);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!ref.mounted) return const [];

      return repository.searchPlaces(query);
    }, retry: (_, _) => null);

// ── Device location ────────────────────────────────────────────────────────

/// Resolves the device's position into a named [Place].
///
/// Throws `AppFailure.locationDenied` rather than the plugin's own exceptions,
/// so the UI has one thing to switch on.
final deviceLocationProvider = FutureProvider.autoDispose<Place>((ref) async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const AppFailure.locationDenied();
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    throw const AppFailure.locationDenied(permanently: true);
  }
  if (permission == LocationPermission.denied) {
    throw const AppFailure.locationDenied();
  }

  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
  );
  return ref
      .watch(weatherRepositoryProvider)
      .placeAt(latitude: position.latitude, longitude: position.longitude);
});
