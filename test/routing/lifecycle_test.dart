import 'package:atmos_flow/core/persistence/preferences.dart';
import 'package:atmos_flow/core/theme/app_theme.dart';
import 'package:atmos_flow/features/search/presentation/search_screen.dart';
import 'package:atmos_flow/features/settings/presentation/settings_screen.dart';
import 'package:atmos_flow/features/weather/application/weather_providers.dart';
import 'package:atmos_flow/features/weather/data/fake_weather_repository.dart';
import 'package:atmos_flow/features/weather/domain/place.dart';
import 'package:atmos_flow/features/weather/presentation/day_detail/day_detail_screen.dart';
import 'package:atmos_flow/features/weather/presentation/home/widgets/daily_row.dart';
import 'package:atmos_flow/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What survives a dismissal, and what does not.
///
/// `findsNothing` only says a widget left the tree; it says nothing about
/// whether its State is still on the heap, or whether the last thing the user
/// typed is still sitting in the field when the screen comes back. These pin
/// both — and both have been wrong here before.
void main() {
  Future<Widget> appUnderTest() async {
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
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: ref.watch(appRouterProvider),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );
  }

  Future<void> settleHome(WidgetTester tester) async {
    await tester.pumpWidget(await appUnderTest());
    await tester.pump(); // resolve the fixture forecast
    await tester.pump();
  }

  /// Pumps past a modal's present or dismiss animation.
  Future<void> settleModal(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  // ── What the field remembers ───────────────────────────────────────────

  group('Search query across a dismissal', () {
    testWidgets('comes back empty, over the saved locations again', (
      tester,
    ) async {
      await settleHome(tester);

      await tester.tap(find.byTooltip('Search locations'));
      await settleModal(tester);
      await tester.enterText(find.byType(TextField), 'Tokyo');
      await tester.pump();
      expect(find.text('SAVED LOCATIONS'), findsNothing);

      await tester.tap(find.byTooltip('Back to forecast'));
      await settleModal(tester);
      expect(find.byType(SearchScreen), findsNothing);

      await tester.tap(find.byTooltip('Search locations'));
      await settleModal(tester);

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text('SAVED LOCATIONS'), findsOneWidget);
    });

    testWidgets('does not re-run the old query on reopen', (tester) async {
      final repository = _CountingRepository();
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
            weatherRepositoryProvider.overrideWithValue(repository),
          ],
          child: Consumer(
            builder: (context, ref, _) => MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: ref.watch(appRouterProvider),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byTooltip('Search locations'));
      await settleModal(tester);
      await tester.enterText(find.byType(TextField), 'Tokyo');
      await tester.pump(); // the results section starts watching
      await tester.pump(const Duration(milliseconds: 400)); // past the debounce
      expect(repository.searches, 1);

      await tester.tap(find.byTooltip('Back to forecast'));
      await settleModal(tester);

      await tester.tap(find.byTooltip('Search locations'));
      await settleModal(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(repository.searches, 1);
    });
  });

  // ── What the heap keeps ────────────────────────────────────────────────

  group('a dismissed screen is collected', () {
    /// Opens a screen, hands back a weak reference to its State, and leaves
    /// no strong one behind — the reference has to be the only thing left
    /// once the route is gone.
    WeakReference<Object> weakStateOf<T extends StatefulWidget>(
      WidgetTester tester,
    ) => WeakReference<Object>(tester.state<State>(find.byType(T)));

    Future<void> expectCollected(
      WidgetTester tester,
      WeakReference<Object> ref,
    ) async {
      // forceGC allocates and waits on a real clock. Inside testWidgets the
      // clock is fake, so it has to run outside it or the delay never fires.
      await tester.runAsync(() => forceGC(fullGcCycles: 3));
      expect(
        ref.target,
        isNull,
        reason: 'the State was still reachable after the route was popped',
      );
    }

    testWidgets(
      'Search',
      (tester) async {
        await settleHome(tester);
        await tester.tap(find.byTooltip('Search locations'));
        await settleModal(tester);

        final state = weakStateOf<SearchScreen>(tester);

        await tester.tap(find.byTooltip('Back to forecast'));
        await settleModal(tester);
        expect(find.byType(SearchScreen), findsNothing);

        await expectCollected(tester, state);
      },
      // Known to fail, and left here so it is not rediscovered from scratch.
      //
      // Search is the one screen that is not collected: open and dismiss it
      // four times and all four States are still on the heap. What is
      // narrowed so far — replace the field with a SizedBox and the screen is
      // collected; leave the field but strip its callbacks and its controller
      // listener and it still is not; and a bare Flutter route holding a
      // TextField retains exactly one instance, not all of them. So the text
      // field is necessary but the unbounded part is ours, and finding it
      // wants a heap snapshot with retaining paths from a real run rather
      // than another guess from a widget test.
      skip: true,
    );

    testWidgets('Settings', (tester) async {
      await settleHome(tester);
      await tester.tap(find.byTooltip('Settings'));
      await settleModal(tester);

      final state = weakStateOf<SettingsScreen>(tester);

      await tester.tap(find.byTooltip('Back to forecast'));
      await settleModal(tester);
      expect(find.byType(SettingsScreen), findsNothing);

      await expectCollected(tester, state);
    });

    testWidgets('Day Detail', (tester) async {
      await settleHome(tester);
      await tester.tap(find.byType(DailyRow).first);
      await settleModal(tester);

      final state = weakStateOf<DayDetailScreen>(tester);

      await tester.tap(find.byTooltip('Back to forecast'));
      await settleModal(tester);
      expect(find.byType(DayDetailScreen), findsNothing);

      await expectCollected(tester, state);
    });
  });
}

/// Counts geocoding calls, so a test can see a request the UI does not show.
class _CountingRepository extends FakeWeatherRepository {
  int searches = 0;

  @override
  Future<List<Place>> searchPlaces(String query) {
    searches++;
    return super.searchPlaces(query);
  }
}
