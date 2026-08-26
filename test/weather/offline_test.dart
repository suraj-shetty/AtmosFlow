import 'package:atmos_flow/core/failure/app_failure.dart';
import 'package:atmos_flow/core/persistence/preferences.dart';
import 'package:atmos_flow/core/theme/app_theme.dart';
import 'package:atmos_flow/core/theme/motion.dart';
import 'package:atmos_flow/features/weather/application/weather_providers.dart';
import 'package:atmos_flow/features/weather/data/fake_weather_repository.dart';
import 'package:atmos_flow/features/weather/domain/forecast.dart';
import 'package:atmos_flow/features/weather/domain/place.dart';
import 'package:atmos_flow/features/weather/domain/weather_repository.dart';
import 'package:atmos_flow/features/weather/presentation/home/home_screen.dart';
import 'package:atmos_flow/features/weather/presentation/home/widgets/refresh_puck.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Losing the network with a forecast already on screen.
///
/// The cold case — opening the app with no connection and nothing cached —
/// is covered in `home_screen_test.dart`, and shows the failure because there
/// is genuinely nothing else to show. This is the other case, and the common
/// one: the reading arrived fine, and the *refresh* is what fails. A train
/// going into a tunnel, a lift, a dead spot on a walk. The forecast from ten
/// minutes ago is still worth reading, and taking it away to announce a
/// network problem trades something useful for something merely true.
void main() {
  Future<Widget> homeWith(WeatherRepository repository) async {
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
        weatherRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        // The ambient sky loops forever, so pumpAndSettle would never return.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const Scaffold(body: HomeScreen()),
      ),
    );
  }

  /// Drags the list past the trigger and lets go, which is what the puck
  /// turns into a refresh.
  Future<void> pullToRefresh(WidgetTester tester) async {
    final gesture = await tester.startGesture(const Offset(200, 300));
    await gesture.moveBy(const Offset(0, Motion.pullTrigger * 3));
    await tester.pump();
    await gesture.up();
    // The scrollable says nothing at the moment a drag ends; the release
    // shows up as the first ballistic frame after it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(
      Motion.refreshMinimum + const Duration(milliseconds: 100),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a refresh that fails keeps the forecast on screen', (
    tester,
  ) async {
    final repository = _FlakyRepository(FakeWeatherRepository());
    await tester.pumpWidget(await homeWith(repository));
    await tester.pumpAndSettle();
    expect(find.text('San Francisco'), findsOneWidget);

    repository.offline = true;
    await pullToRefresh(tester);

    // The reading is still there — this is the whole point.
    expect(find.text('San Francisco'), findsOneWidget);
    expect(find.textContaining("Couldn't reach"), findsOneWidget);
    // ...and it is the snackbar saying so, not the screen having been
    // replaced by the failure.
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('the failure does not escape into the void', (tester) async {
    // Nothing awaits the refresh: the puck starts it and the gesture ends.
    // An uncaught failure would be reported to the zone and seen by no one.
    final repository = _FlakyRepository(FakeWeatherRepository());
    await tester.pumpWidget(await homeWith(repository));
    await tester.pumpAndSettle();

    repository.offline = true;
    await pullToRefresh(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('the puck stops spinning even though the fetch failed', (
    tester,
  ) async {
    final repository = _FlakyRepository(FakeWeatherRepository());
    await tester.pumpWidget(await homeWith(repository));
    await tester.pumpAndSettle();

    repository.offline = true;
    await pullToRefresh(tester);

    expect(
      tester.widget<RefreshPuck>(find.byType(RefreshPuck)).refreshing,
      isFalse,
    );
  });

  testWidgets('the network coming back refreshes normally', (tester) async {
    final repository = _FlakyRepository(FakeWeatherRepository());
    await tester.pumpWidget(await homeWith(repository));
    await tester.pumpAndSettle();

    repository.offline = true;
    await pullToRefresh(tester);
    expect(repository.attempts, 2);

    repository.offline = false;
    await pullToRefresh(tester);

    expect(repository.attempts, 3);
    expect(find.text('San Francisco'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('with nothing to fall back on the failure is the screen', (
    tester,
  ) async {
    // The other side of the same rule: no cached reading means the error is
    // genuinely all there is, and hiding it would leave a blank screen.
    await tester.pumpWidget(
      await homeWith(FakeWeatherRepository(failWith: const NetworkFailure())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't reach"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  test('every failure has copy a person could act on', () {
    // The snackbar shows this verbatim, so an empty or debug-looking string
    // would reach the user as-is.
    for (final failure in const [
      AppFailure.network(),
      AppFailure.notFound(),
      AppFailure.locationDenied(),
      AppFailure.locationDenied(permanently: true),
      AppFailure.malformedResponse(),
      AppFailure.unknown(),
    ]) {
      expect(failure.message, isNotEmpty);
      expect(failure.message, isNot(contains('Exception')));
      expect(failure.message.trim(), failure.message);
    }
  });
}

/// Fetches normally until the network is taken away, then fails the way a
/// dead connection does — and counts, so a test can tell a refresh that was
/// attempted from one that was skipped.
class _FlakyRepository implements WeatherRepository {
  _FlakyRepository(this._inner);

  final WeatherRepository _inner;
  bool offline = false;
  int attempts = 0;

  @override
  Future<Forecast> fetchForecast(Place place) async {
    attempts++;
    if (offline) throw const AppFailure.network();
    return _inner.fetchForecast(place);
  }

  @override
  Future<List<Place>> searchPlaces(String query) => _inner.searchPlaces(query);

  @override
  Future<Place> placeAt({
    required double latitude,
    required double longitude,
  }) => _inner.placeAt(latitude: latitude, longitude: longitude);
}
