import 'dart:convert';

import 'package:atmos_flow/core/persistence/preferences.dart';
import 'package:atmos_flow/core/theme/app_theme.dart';
import 'package:atmos_flow/features/weather/application/weather_providers.dart';
import 'package:atmos_flow/features/weather/data/fake_weather_repository.dart';
import 'package:atmos_flow/features/weather/domain/forecast.dart';
import 'package:atmos_flow/features/weather/domain/place.dart';
import 'package:atmos_flow/features/weather/domain/weather_condition.dart';
import 'package:atmos_flow/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The design's own preview frame — an iPhone at 402×874 logical pixels.
///
/// Rendered at a device pixel ratio of 1 so a golden is legible at 1:1 in a
/// diff view; the layout, not the resampling, is what these files pin.
const Size designSurface = Size(402, 874);

/// The fixture location every golden shows, so the header copy never moves.
const goldenPlace = Place(
  id: 1,
  name: 'San Francisco',
  latitude: 37.7749,
  longitude: -122.4194,
  country: 'United States',
  admin1: 'California',
);

/// Loads the bundled Caprasimo and Figtree faces — and the icon fonts — into
/// the test binding.
///
/// Without this every glyph renders as an Ahem box, which would make the
/// goldens pin layout and nothing else.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest =
      jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;

  for (final family in manifest.cast<Map<String, Object?>>()) {
    final loader = FontLoader(family['family']! as String);
    for (final font
        in (family['fonts']! as List).cast<Map<String, Object?>>()) {
      loader.addFont(rootBundle.load(font['asset']! as String));
    }
    await loader.load();
  }
}

/// Holds the app's clock at 2:14 PM on the fixture's own day.
///
/// Day Detail draws the sun's position on its arc from the current time, so
/// without this the dot creeps a pixel further along every minute and the
/// golden fails on the next run. 2:14 PM is 58% of the way from the fixture's
/// sunrise to its sunset — the exact point the design's own prototype draws.
void freezeClock() {
  Forecast.clock = () => DateTime.utc(2026, 8, 19, 14, 14);
  addTearDown(() => Forecast.clock = DateTime.now);
}

/// Pins the viewport to [designSurface] for the duration of one test.
void useDesignSurface(WidgetTester tester) {
  tester.view.physicalSize = designSurface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// The fixture forecast with its current conditions forced.
///
/// The ambient sky and every palette role key off `condition` and `isNight`,
/// so this one substitution is what drives all fourteen Home goldens.
Future<Forecast> forecastFor(
  WeatherCondition condition, {
  required bool isNight,
}) async {
  final base = await FakeWeatherRepository().fetchForecast(goldenPlace);
  return base.copyWith(
    current: base.current.copyWith(condition: condition, isNight: isNight),
  );
}

/// The real app — real router, real theme — over fixture data.
///
/// [forecast] replaces the fixture's own when a golden needs a condition the
/// fixtures do not carry. [savePlace] false leaves the app on onboarding,
/// which is where the router sends a user with nothing selected.
Future<Widget> goldenApp({Forecast? forecast, bool savePlace = true}) async {
  SharedPreferences.setMockInitialValues({
    if (savePlace) ...{
      // Encoded from [goldenPlace] rather than written out, so the place the
      // app rehydrates is equal to the one the forecast override is keyed on —
      // a family key that differs by one null field silently misses.
      PrefKeys.savedLocations: <String>[jsonEncode(goldenPlace.toJson())],
      PrefKeys.selectedPlaceId: goldenPlace.id,
    },
  });
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      weatherRepositoryProvider.overrideWithValue(FakeWeatherRepository()),
      if (forecast != null)
        forecastProvider(goldenPlace).overrideWith((ref) => forecast),
    ],
    child: Consumer(
      builder: (context, ref, _) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: ref.watch(appRouterProvider),
        // Every ambient sky loops forever, so there is no settled frame to
        // capture. The app draws a still sky under this flag — which is also
        // what a user with Reduce Motion on sees.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    ),
  );
}

/// Pumps [app] and lets the fixture forecast and every route transition land.
Future<void> settle(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}
