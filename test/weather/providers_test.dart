import 'package:atmos_flow/core/failure/app_failure.dart';
import 'package:atmos_flow/features/settings/application/settings_providers.dart';
import 'package:atmos_flow/features/settings/domain/app_settings.dart';
import 'package:atmos_flow/features/weather/application/weather_providers.dart';
import 'package:atmos_flow/features/weather/data/fake_weather_repository.dart';
import 'package:atmos_flow/features/weather/domain/place.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('savedLocationsProvider', () {
    test('starts empty and persists what is added', () async {
      final container = await testContainer();
      final notifier = container.read(savedLocationsProvider.notifier);

      expect(container.read(savedLocationsProvider), isEmpty);

      notifier.add(FakeWeatherRepository.savedFixtures[0]);
      notifier.add(FakeWeatherRepository.savedFixtures[1]);
      expect(container.read(savedLocationsProvider), hasLength(2));

      // Adding the same place twice is a no-op.
      notifier.add(FakeWeatherRepository.savedFixtures[0]);
      expect(container.read(savedLocationsProvider), hasLength(2));
    });

    test('remove drops exactly one place', () async {
      final container = await testContainer();
      final notifier = container.read(savedLocationsProvider.notifier);
      for (final p in FakeWeatherRepository.savedFixtures.take(3)) {
        notifier.add(p);
      }

      notifier.remove(2);
      expect(container.read(savedLocationsProvider).map((p) => p.id), [1, 3]);
    });

    test('reorder follows the onReorderItem index semantics', () async {
      final container = await testContainer();
      final notifier = container.read(savedLocationsProvider.notifier);
      for (final p in FakeWeatherRepository.savedFixtures.take(4)) {
        notifier.add(p);
      }

      // Drag the first row down to the third slot. The index is counted
      // against the list with that row already lifted out of it.
      notifier.reorder(0, 2);
      expect(container.read(savedLocationsProvider).map((p) => p.id), [
        2,
        3,
        1,
        4,
      ]);

      // And drag it back to the front.
      notifier.reorder(2, 0);
      expect(container.read(savedLocationsProvider).map((p) => p.id), [
        1,
        2,
        3,
        4,
      ]);
    });

    test('saved locations and selection survive a relaunch', () async {
      final first = await testContainer();
      final place = FakeWeatherRepository.savedFixtures[2];
      first.read(savedLocationsProvider.notifier).add(place);
      first.read(selectedPlaceProvider.notifier).select(place);

      // A second container over the same store is what a relaunch looks like.
      final prefs = await SharedPreferences.getInstance();
      final second = await testContainer(reusePrefs: prefs);

      expect(second.read(savedLocationsProvider).map((p) => p.name), [
        'Reykjav\u00edk',
      ]);
      expect(second.read(selectedPlaceProvider)?.id, place.id);
    });
  });

  group('forecastProvider', () {
    test('resolves the fixture forecast', () async {
      final container = await testContainer();
      final place = FakeWeatherRepository.savedFixtures.first;

      final forecast = await container.read(forecastProvider(place).future);
      expect(forecast.place.name, 'San Francisco');
      expect(forecast.current.temperature, 22);
      expect(forecast.hourly, hasLength(8));
      expect(forecast.daily, hasLength(7));
      expect(forecast.daily.first.hourlyTemperatures, hasLength(24));
    });

    test('surfaces AppFailure from the repository', () async {
      final container = await testContainer(
        repository: FakeWeatherRepository(
          failWith: const AppFailure.network(detail: 'offline'),
        ),
      );
      final place = FakeWeatherRepository.savedFixtures.first;

      await expectLater(
        container.read(forecastProvider(place).future),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('placeSearchProvider', () {
    /// The provider auto-disposes, and its debounce outlives a bare `read`,
    /// so hold a subscription the way the Search screen does.
    Future<List<Place>> search(ProviderContainer container, String query) {
      final sub = container.listen(placeSearchProvider(query), (_, _) {});
      addTearDown(sub.close);
      return container.read(placeSearchProvider(query).future);
    }

    test('is empty for a blank query and filters for a real one', () async {
      final container = await testContainer();

      expect(await search(container, ''), isEmpty);
      expect((await search(container, 'tok')).map((p) => p.name), ['Tokyo']);
    });

    test('returns nothing for a query that matches no city', () async {
      final container = await testContainer();
      expect(await search(container, 'zzzz'), isEmpty);
    });
  });

  group('settingsProvider', () {
    test('defaults to celsius, km/h and auto', () async {
      final container = await testContainer();
      final settings = container.read(settingsProvider);
      expect(settings.temperatureUnit, TemperatureUnit.celsius);
      expect(settings.windUnit, WindUnit.kmh);
      expect(settings.appearance, AppearanceMode.auto);
    });

    test('changing a unit reaches the formatter', () async {
      final container = await testContainer();
      expect(container.read(unitFormatterProvider).temperature(22), '22°');

      container
          .read(settingsProvider.notifier)
          .setTemperatureUnit(TemperatureUnit.fahrenheit);
      expect(container.read(unitFormatterProvider).temperature(22), '72°');
    });
  });
}
