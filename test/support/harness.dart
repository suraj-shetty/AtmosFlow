import 'package:atmos_flow/core/persistence/preferences.dart';
import 'package:atmos_flow/core/theme/app_theme.dart';
import 'package:atmos_flow/features/weather/application/weather_providers.dart';
import 'package:atmos_flow/features/weather/data/fake_weather_repository.dart';
import 'package:atmos_flow/features/weather/domain/weather_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A container wired to fixture weather and in-memory preferences — for
/// testing providers without pumping a widget.
Future<ProviderContainer> testContainer({
  WeatherRepository? repository,
  Map<String, Object> initialPrefs = const {},
  SharedPreferences? reusePrefs,
}) async {
  final SharedPreferences prefs;
  if (reusePrefs != null) {
    // Simulating a relaunch: keep the store the previous container wrote to.
    prefs = reusePrefs;
  } else {
    SharedPreferences.setMockInitialValues(initialPrefs);
    prefs = await SharedPreferences.getInstance();
  }

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      weatherRepositoryProvider.overrideWithValue(
        repository ?? FakeWeatherRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// The same wiring, wrapped around a widget under the app's real theme.
Future<Widget> testHarness(
  Widget child, {
  WeatherRepository? repository,
  Map<String, Object> initialPrefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      weatherRepositoryProvider.overrideWithValue(
        repository ?? FakeWeatherRepository(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    ),
  );
}
