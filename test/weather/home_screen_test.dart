import 'package:atmos_flow/core/failure/app_failure.dart';
import 'package:atmos_flow/core/theme/app_theme.dart';
import 'package:atmos_flow/core/persistence/preferences.dart';
import 'package:atmos_flow/features/settings/application/settings_providers.dart';
import 'package:atmos_flow/features/settings/domain/app_settings.dart';
import 'package:atmos_flow/features/weather/application/weather_providers.dart';
import 'package:atmos_flow/features/weather/data/fake_weather_repository.dart';
import 'package:atmos_flow/features/weather/domain/place.dart';
import 'package:atmos_flow/features/weather/presentation/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const place = Place(
    id: 1,
    name: 'San Francisco',
    latitude: 37.7749,
    longitude: -122.4194,
    country: 'United States',
    admin1: 'California',
  );

  Future<Widget> homeUnderTest() async {
    SharedPreferences.setMockInitialValues({
      PrefKeys.savedLocations: <String>[
        '{"id":1,"name":"San Francisco","latitude":37.7749,"longitude":-122.4194}',
      ],
      PrefKeys.selectedPlaceId: 1,
    });
    final prefs = await SharedPreferences.getInstance();

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        weatherRepositoryProvider.overrideWithValue(FakeWeatherRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        // The ambient sky loops forever, so pumpAndSettle would never
        // return. The app honours this flag by drawing a still sky.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const Scaffold(body: HomeScreen()),
      ),
    );
  }

  testWidgets('renders the hero, both lists and the metric grid', (
    tester,
  ) async {
    await tester.pumpWidget(await homeUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('San Francisco'), findsOneWidget);
    expect(find.text('22°'), findsWidgets); // hero temperature
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Feels like 20°'), findsOneWidget);

    // The design dropped the tab bar: Search and Settings are reached from
    // the header, and nothing else on Home leads to them.
    expect(find.byTooltip('Search locations'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);

    expect(find.text('NEXT 24 HOURS'), findsOneWidget);
    expect(find.text('7-DAY FORECAST'), findsOneWidget);
    expect(find.text('Now'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);

    for (final label in ['Humidity', 'Wind', 'UV Index', 'Visibility']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('58%'), findsOneWidget);
    expect(find.text('12 km/h'), findsOneWidget);
    expect(find.text('12 km'), findsOneWidget);
  });

  testWidgets('tapping the place name opens search', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(await homeUnderTest());
    await tester.pumpAndSettle();

    // No router under this harness, so assert the handler is wired rather
    // than the destination: an unwired name has no gesture recogniser.
    expect(
      find.ancestor(
        of: find.text('San Francisco'),
        matching: find.byType(GestureDetector),
      ),
      findsWidgets,
    );
    expect(
      find.bySemanticsLabel('Change location, currently San Francisco'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('tapping an hourly chip reveals its precipitation chance', (
    tester,
  ) async {
    await tester.pumpWidget(await homeUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('5% precip'), findsNothing);

    await tester.tap(find.text('Now'));
    await tester.pumpAndSettle();
    expect(find.text('5% precip'), findsOneWidget);

    // Tapping again collapses it.
    await tester.tap(find.text('Now'));
    await tester.pumpAndSettle();
    expect(find.text('5% precip'), findsNothing);
  });

  testWidgets('switching to fahrenheit re-renders every temperature', (
    tester,
  ) async {
    final widget = await homeUnderTest();
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.text('Feels like 20°'), findsOneWidget);

    final element = tester.element(find.byType(HomeScreen));
    ProviderScope.containerOf(element)
        .read(settingsProvider.notifier)
        .setTemperatureUnit(TemperatureUnit.fahrenheit);
    await tester.pumpAndSettle();

    // 22°C → 72°F, 20°C → 68°F
    expect(find.text('72°'), findsWidgets);
    expect(find.text('Feels like 68°'), findsOneWidget);
  });

  testWidgets('an error from the repository offers a retry', (tester) async {
    SharedPreferences.setMockInitialValues({
      PrefKeys.savedLocations: <String>[
        '{"id":1,"name":"San Francisco","latitude":37.7749,"longitude":-122.4194}',
      ],
      PrefKeys.selectedPlaceId: 1,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          weatherRepositoryProvider.overrideWithValue(
            FakeWeatherRepository(failWith: const NetworkFailure()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          // The ambient sky loops forever, so pumpAndSettle would never
          // return. The app honours this flag by drawing a still sky.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't reach the forecast"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  test('the fixture place matches the design prototype', () {
    expect(FakeWeatherRepository.savedFixtures.first, place);
    expect(FakeWeatherRepository.graphTemperatures, hasLength(24));
  });
}
