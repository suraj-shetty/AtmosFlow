import 'dart:convert';

import 'package:atmos_flow/core/persistence/preferences.dart';
import 'package:atmos_flow/features/weather/application/weather_providers.dart';
import 'package:atmos_flow/features/weather/data/fake_weather_repository.dart';
import 'package:atmos_flow/features/weather/domain/forecast.dart';
import 'package:atmos_flow/features/weather/domain/place.dart';
import 'package:atmos_flow/features/weather/domain/weather_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

/// Coming back to a forecast the app has been holding.
///
/// The bug this covers is a quiet one: the app is left sitting on Home, the
/// phone is put away, and hours later the same numbers are still on screen
/// with nothing having asked whether they are still true. Nothing crashes and
/// nothing looks wrong — which is the whole problem.
void main() {
  // For the lifecycle binding these tests drive; there is no widget here.
  TestWidgetsFlutterBinding.ensureInitialized();

  final place = FakeWeatherRepository.savedFixtures.first;
  final start = DateTime(2026, 8, 19, 12);

  setUp(() {
    Forecast.clock = () => start;
    addTearDown(() => Forecast.clock = DateTime.now);
  });

  /// A container with [place] selected and a repository that counts.
  Future<(ProviderContainer, _CountingRepository)> showing() async {
    final repository = _CountingRepository(FakeWeatherRepository(now: start));
    final container = await testContainer(
      repository: repository,
      initialPrefs: {
        // Both keys: a selection with nothing saved resolves to nothing
        // selected, which is what onboarding leaves behind.
        PrefKeys.savedLocations: [jsonEncode(place.toJson())],
        PrefKeys.selectedPlaceId: place.id,
      },
    );
    // The forecast the app is sitting on, with a listener the way a mounted
    // Home screen is one — which is exactly what keeps it alive.
    container.listen(forecastProvider(place), (_, _) {});
    await container.read(forecastProvider(place).future);
    container.read(forecastFreshnessProvider);
    return (container, repository);
  }

  void resume() {
    // The whole walk out and back, because `AppLifecycleListener` asserts on
    // the transitions rather than just reporting the state: a resume is only
    // a resume if the app went away first, one step at a time.
    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(state);
    }
  }

  test('coming back to a stale reading fetches a new one', () async {
    final (container, repository) = await showing();
    expect(repository.fetches, 1);

    Forecast.clock = () => start.add(const Duration(hours: 6));
    resume();
    await pumpEventQueue();
    await container.read(forecastProvider(place).future);

    expect(repository.fetches, 2);
  });

  test('coming back to a fresh one leaves it alone', () async {
    // The common case by far — a glance, a lock, a glance again. Refetching
    // there would spend a request on numbers that have not moved.
    final (container, repository) = await showing();

    Forecast.clock = () => start.add(const Duration(minutes: 5));
    resume();
    await pumpEventQueue();
    await container.read(forecastProvider(place).future);

    expect(repository.fetches, 1);
  });

  test('the line is where the cache says it is', () async {
    final (container, repository) = await showing();

    Forecast.clock = () =>
        start.add(forecastFreshFor - const Duration(seconds: 1));
    resume();
    await pumpEventQueue();
    expect(repository.fetches, 1);

    Forecast.clock = () => start.add(forecastFreshFor);
    resume();
    await pumpEventQueue();
    await container.read(forecastProvider(place).future);
    expect(repository.fetches, 2);
  });

  test('every held place is refetched, not just the one on top', () async {
    // Saved Locations holds a forecast per row, each for the same reason and
    // each as old as the rest.
    final (container, repository) = await showing();
    final other = FakeWeatherRepository.savedFixtures[1];
    container.listen(forecastProvider(other), (_, _) {});
    await container.read(forecastProvider(other).future);
    expect(repository.fetches, 2);

    Forecast.clock = () => start.add(const Duration(hours: 6));
    resume();
    await pumpEventQueue();
    await container.read(forecastProvider(other).future);

    expect(repository.fetches, 4);
  });

  test('a place nothing is watching any more is let go', () async {
    // The other half of the same rule, and the one that keeps a search for
    // "London" from leaving nine forecasts in memory for the rest of the day.
    final original = forecastFreshFor;
    forecastFreshFor = const Duration(milliseconds: 20);
    addTearDown(() => forecastFreshFor = original);

    final repository = _CountingRepository(FakeWeatherRepository(now: start));
    final container = await testContainer(repository: repository);

    final row = container.listen(forecastProvider(place), (_, _) {});
    await container.read(forecastProvider(place).future);
    expect(repository.fetches, 1);

    row.close();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await container.read(forecastProvider(place).future);

    expect(repository.fetches, 2);
  });

  test('a screen that comes straight back to it keeps it', () async {
    // Leaving Search for Day Detail and back again is not a reason to spend
    // a request.
    final original = forecastFreshFor;
    forecastFreshFor = const Duration(milliseconds: 50);
    addTearDown(() => forecastFreshFor = original);

    final repository = _CountingRepository(FakeWeatherRepository(now: start));
    final container = await testContainer(repository: repository);

    container.listen(forecastProvider(place), (_, _) {}).close();
    await container.read(forecastProvider(place).future);
    container.listen(forecastProvider(place), (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await container.read(forecastProvider(place).future);

    expect(repository.fetches, 1);
  });

  test('a resume before anything is chosen is not an error', () async {
    // Onboarding has not finished, so there is nothing to be stale.
    final container = await testContainer(repository: FakeWeatherRepository());
    container.read(forecastFreshnessProvider);

    resume();
    await pumpEventQueue();

    expect(container.read(selectedPlaceProvider), isNull);
  });
}

/// Counts what it is asked for, and stamps each reading with the moment it
/// was taken so age means something.
class _CountingRepository implements WeatherRepository {
  _CountingRepository(this._inner);

  final WeatherRepository _inner;
  int fetches = 0;

  @override
  Future<Forecast> fetchForecast(Place place) async {
    fetches++;
    final forecast = await _inner.fetchForecast(place);
    return forecast.copyWith(fetchedAt: Forecast.clock());
  }

  @override
  Future<List<Place>> searchPlaces(String query) => _inner.searchPlaces(query);

  @override
  Future<Place> placeAt({
    required double latitude,
    required double longitude,
  }) => _inner.placeAt(latitude: latitude, longitude: longitude);
}
