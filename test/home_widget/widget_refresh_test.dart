import 'dart:convert';

import 'package:atmos_flow/core/failure/app_failure.dart';
import 'package:atmos_flow/core/persistence/preferences.dart';
import 'package:atmos_flow/features/home_widget/application/widget_refresh.dart';
import 'package:atmos_flow/features/weather/application/weather_providers.dart';
import 'package:atmos_flow/features/weather/data/fake_weather_repository.dart';
import 'package:atmos_flow/features/weather/domain/place.dart';
import 'package:atmos_flow/features/weather/domain/weather_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The run nobody watches.
///
/// A background refresh happens in another isolate, while the app is closed,
/// and reports to nothing — so the only way it is ever known to work is here.
/// The seam under test is the decisions it makes: when to spend a fetch, when
/// to leave the reading alone, and what it does with a failure.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const place = Place(
    id: 1,
    name: 'San Francisco',
    latitude: 37.7749,
    longitude: -122.4194,
    country: 'United States',
  );

  /// What `home_widget` would have written to the App Group.
  late Map<String, Object?> store;
  late List<MethodCall> calls;

  setUp(() {
    store = {};
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), (
          call,
        ) async {
          calls.add(call);
          final arguments = call.arguments as Map<Object?, Object?>?;
          switch (call.method) {
            case 'saveWidgetData':
              store[arguments!['id']! as String] = arguments['data'];
            case 'getWidgetData':
              return store[arguments!['id']! as String];
          }
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('home_widget'), null),
    );
  });

  Future<ProviderContainer> containerWith({
    bool selected = true,
    WeatherRepository? repository,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (selected) ...{
        PrefKeys.savedLocations: [jsonEncode(place.toJson())],
        PrefKeys.selectedPlaceId: place.id,
      },
    });
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        weatherRepositoryProvider.overrideWithValue(
          repository ?? FakeWeatherRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  bool published() => calls.any((c) => c.method == 'saveWidgetData');

  test('publishes the reading the app would have published', () async {
    expect(await refreshWidget(container: await containerWith()), isTrue);

    expect(published(), isTrue);
    expect(store['temperature'], '22°');
    expect(store['place'], 'San Francisco');
    // And asks for the redraw, which is the half that makes it visible.
    expect(calls.map((c) => c.method), contains('updateWidget'));
  });

  test('leaves a reading that is already fresh alone', () async {
    // The app publishes on every forecast it resolves, so a run landing just
    // after someone closed the app would spend a fetch on what is already
    // there.
    store['updatedAt'] = (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000)
        .toString();

    expect(await refreshWidget(container: await containerWith()), isTrue);
    expect(published(), isFalse);
  });

  test('a reading old enough to be worth replacing is replaced', () async {
    store['updatedAt'] =
        (DateTime.now()
                    .toUtc()
                    .subtract(const Duration(hours: 3))
                    .millisecondsSinceEpoch ~/
                1000)
            .toString();

    expect(await refreshWidget(container: await containerWith()), isTrue);
    expect(published(), isTrue);
  });

  test('nothing selected yet is nothing to do, and not a failure', () async {
    // Onboarding has not finished. Reporting failure would only earn a
    // retry, and there is nothing to retry.
    expect(
      await refreshWidget(container: await containerWith(selected: false)),
      isTrue,
    );
    expect(published(), isFalse);
  });

  test('a fetch that fails asks to be run again', () async {
    final container = await containerWith(
      repository: FakeWeatherRepository(failWith: const AppFailure.network()),
    );

    expect(await refreshWidget(container: container), isFalse);
    expect(published(), isFalse);
  });

  test('an unreadable stamp is treated as no reading at all', () async {
    // Rather than as a fresh one, which would stop the refresh forever.
    store['updatedAt'] = 'not a time';

    expect(await refreshWidget(container: await containerWith()), isTrue);
    expect(published(), isTrue);
  });
}
