import 'package:atmos_flow/core/persistence/preferences.dart';
import 'package:atmos_flow/core/theme/app_theme.dart';
import 'package:atmos_flow/features/search/presentation/search_screen.dart';
import 'package:atmos_flow/features/settings/presentation/settings_screen.dart';
import 'package:atmos_flow/features/weather/application/weather_providers.dart';
import 'package:atmos_flow/features/weather/data/fake_weather_repository.dart';
import 'package:atmos_flow/features/weather/presentation/day_detail/day_detail_screen.dart';
import 'package:atmos_flow/features/weather/presentation/home/widgets/daily_row.dart';
import 'package:atmos_flow/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Day Detail, Search and Settings are presented like an iOS full-screen
/// cover: the whole screen rides up from the bottom edge. A route that simply appeared would
/// satisfy a "the screen is showing" assertion just as well, so these pin the
/// motion itself — off-screen at the start, part-way through in the middle.
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
          // The ambient sky loops forever; a still sky keeps the frame count
          // under our control without touching the route animation.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );
  }

  /// How far down the screen [finder]'s content sits, as a fraction of the
  /// viewport: 1 is fully below the bottom edge, 0 is in place.
  double offsetOf(WidgetTester tester, Finder finder) {
    final slide = tester.widget<SlideTransition>(
      find.ancestor(of: finder, matching: find.byType(SlideTransition)).first,
    );
    return slide.position.value.dy;
  }

  Future<void> openFromHome(WidgetTester tester, String tooltip) async {
    await tester.pumpWidget(await appUnderTest());
    await tester.pump(); // resolve the fixture forecast
    await tester.pump();

    await tester.tap(find.byTooltip(tooltip));
    await tester.pump(); // the router hears the tap
    await tester.pump(); // the route is pushed, its animation still at zero
  }

  testWidgets('Settings rises from the bottom edge', (tester) async {
    await openFromHome(tester, 'Settings');

    final screen = find.byType(SettingsScreen);
    expect(offsetOf(tester, screen), 1.0);

    await tester.pump(const Duration(milliseconds: 120));
    expect(offsetOf(tester, screen), inExclusiveRange(0, 1));

    await tester.pump(const Duration(milliseconds: 400));
    expect(offsetOf(tester, screen), 0.0);

    // And drops back out the way it came.
    await tester.tap(find.byTooltip('Back to forecast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(offsetOf(tester, screen), inExclusiveRange(0, 1));

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SettingsScreen), findsNothing);
  });

  testWidgets('Search rises the same way', (tester) async {
    await openFromHome(tester, 'Search locations');

    final screen = find.byType(SearchScreen);
    expect(offsetOf(tester, screen), 1.0);

    await tester.pump(const Duration(milliseconds: 120));
    expect(offsetOf(tester, screen), inExclusiveRange(0, 1));

    await tester.pump(const Duration(milliseconds: 400));
    expect(offsetOf(tester, screen), 0.0);
  });

  testWidgets('a forecast day rises and drops back out', (tester) async {
    await tester.pumpWidget(await appUnderTest());
    await tester.pump(); // resolve the fixture forecast
    await tester.pump();

    // Day Detail is reached by tapping a row rather than a chrome button.
    await tester.tap(find.byType(DailyRow).first);
    await tester.pump();
    await tester.pump();

    final screen = find.byType(DayDetailScreen);
    expect(offsetOf(tester, screen), 1.0);

    await tester.pump(const Duration(milliseconds: 120));
    expect(offsetOf(tester, screen), inExclusiveRange(0, 1));

    await tester.pump(const Duration(milliseconds: 400));
    expect(offsetOf(tester, screen), 0.0);

    await tester.tap(find.byTooltip('Back to forecast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(offsetOf(tester, screen), inExclusiveRange(0, 1));

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DayDetailScreen), findsNothing);
  });
}
