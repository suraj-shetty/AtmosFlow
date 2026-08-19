import 'package:atmos_flow/features/weather/domain/weather_condition.dart';
import 'package:atmos_flow/features/weather/presentation/home/widgets/daily_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Pixel records of every screen, and of Home under all seven conditions in
/// daylight and at night.
///
/// The ambient sky, the glass recipes and the per-condition palettes interact
/// in ways no assertion catches — a chip can be perfectly laid out, correctly
/// coloured by its own test, and still illegible over the sky behind it. These
/// files are the record of what the app actually looks like; a diff on one is
/// the prompt to look, not automatically a failure.
///
/// Regenerate with `flutter test --update-goldens test/goldens`.
void main() {
  setUpAll(loadAppFonts);

  group('Home', () {
    for (final condition in WeatherCondition.values) {
      for (final isNight in [false, true]) {
        final name = '${condition.name}_${isNight ? 'night' : 'day'}';

        testWidgets(name, (tester) async {
          useDesignSurface(tester);
          freezeClock();
          freezeClock();
          await settle(
            tester,
            await goldenApp(
              forecast: await forecastFor(condition, isNight: isNight),
            ),
          );

          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('home_$name.png'),
          );
        });
      }
    }
  });

  testWidgets('Day Detail', (tester) async {
    useDesignSurface(tester);
    freezeClock();
    await settle(tester, await goldenApp());

    await tester.tap(find.byType(DailyRow).first);
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('day_detail.png'),
    );
  });

  testWidgets('Search', (tester) async {
    useDesignSurface(tester);
    freezeClock();
    await settle(tester, await goldenApp());

    await tester.tap(find.byTooltip('Search locations'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('search.png'),
    );
  });

  testWidgets('Saved Locations', (tester) async {
    useDesignSurface(tester);
    freezeClock();
    await settle(tester, await goldenApp());

    await tester.tap(find.byTooltip('Search locations'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('saved_locations.png'),
    );
  });

  testWidgets('Settings', (tester) async {
    useDesignSurface(tester);
    freezeClock();
    await settle(tester, await goldenApp());

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('settings.png'),
    );
  });

  testWidgets('Onboarding', (tester) async {
    useDesignSurface(tester);
    freezeClock();
    // Nothing saved, so the router leaves the app where a first launch lands.
    await tester.pumpWidget(await goldenApp(savePlace: false));
    // The mood carousel cycles forever, so this one is pumped to a fixed
    // frame rather than settled: far enough in for the first mood's entrance
    // to have finished, well short of the 3.5s hand-off to the second.
    await tester.pump(const Duration(seconds: 2));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('onboarding.png'),
    );
  });
}
