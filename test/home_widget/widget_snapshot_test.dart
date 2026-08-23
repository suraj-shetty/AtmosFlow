import 'package:atmos_flow/features/home_widget/domain/sky_time.dart';
import 'package:atmos_flow/features/home_widget/domain/widget_snapshot.dart';
import 'package:atmos_flow/features/settings/application/unit_formatter.dart';
import 'package:atmos_flow/features/settings/domain/app_settings.dart';
import 'package:atmos_flow/features/weather/data/fake_weather_repository.dart';
import 'package:atmos_flow/features/weather/domain/forecast.dart';
import 'package:atmos_flow/features/weather/domain/weather_condition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkyTime', () {
    // A day like the fixture's: up at 6:10, down at 20:05.
    final sunrise = DateTime(2026, 8, 19, 6, 10);
    final sunset = DateTime(2026, 8, 19, 20, 5);

    SkyTime at(int hour, [int minute = 0]) => SkyTime.resolve(
      now: DateTime(2026, 8, 19, hour, minute),
      sunrise: sunrise,
      sunset: sunset,
    );

    test('the bands run dawn, morning, afternoon, evening, night', () {
      expect(at(3), SkyTime.night);
      expect(at(5, 42), SkyTime.dawn); // the design's own dawn clock
      expect(at(9, 15), SkyTime.morning);
      expect(at(14, 30), SkyTime.afternoon);
      expect(at(19, 48), SkyTime.evening);
      expect(at(23, 20), SkyTime.night);
    });

    test('the edges belong to the band that starts there', () {
      expect(at(5, 9), SkyTime.night); // an hour and a minute before sunrise
      expect(at(5, 10), SkyTime.dawn);
      expect(at(7, 40), SkyTime.morning); // 90 minutes after sunrise
      expect(at(18, 35), SkyTime.evening); // 90 minutes before sunset
      expect(at(21, 5), SkyTime.night); // an hour after sunset
    });

    test('noon is the midpoint of the sun, not of the clock', () {
      // This day's sun peaks at 13:07, so 13:00 is still morning even though
      // the clock says otherwise — which is the point of anchoring to the sun.
      expect(at(13), SkyTime.morning);
      expect(at(13, 30), SkyTime.afternoon);
    });

    test('a polar day with no night still resolves', () {
      // Reykjavík in June: the sun barely sets. Every band still has an
      // answer, which is all the widget needs.
      final sky = SkyTime.resolve(
        now: DateTime(2026, 6, 21, 2),
        sunrise: DateTime(2026, 6, 21, 2, 55),
        sunset: DateTime(2026, 6, 22, 0, 3),
      );
      expect(sky, SkyTime.dawn);
    });

    group('scheduleFrom', () {
      final day = SunDay(sunrise: sunrise, sunset: sunset);
      // The following day, ten minutes later either end.
      final tomorrow = SunDay(
        sunrise: DateTime(2026, 8, 20, 6, 20),
        sunset: DateTime(2026, 8, 20, 19, 55),
      );

      test('walks the bands in order from where it starts', () {
        final schedule = SkyTime.scheduleFrom(
          start: DateTime(2026, 8, 19, 14, 14),
          window: const Duration(hours: 12),
          days: [day],
        );

        // Starting mid-afternoon, the rest of this day is evening then night.
        expect(schedule.map((c) => c.sky), [
          SkyTime.afternoon,
          SkyTime.evening,
          SkyTime.night,
        ]);
        expect(schedule.first.at, DateTime(2026, 8, 19, 14, 14));
        expect(schedule[1].at, sunset.subtract(const Duration(minutes: 90)));
        expect(schedule[2].at, sunset.add(const Duration(hours: 1)));
      });

      test('carries on into the next day it is given', () {
        final schedule = SkyTime.scheduleFrom(
          start: DateTime(2026, 8, 19, 22),
          window: const Duration(hours: 24),
          days: [day, tomorrow],
        );

        // Opening in the small hours, the window covers the whole of the
        // next day and closes an hour after it sets.
        expect(schedule.map((c) => c.sky), [
          SkyTime.night,
          SkyTime.dawn,
          SkyTime.morning,
          SkyTime.afternoon,
          SkyTime.evening,
          SkyTime.night,
        ]);
        expect(
          schedule[1].at,
          tomorrow.sunrise.subtract(const Duration(hours: 1)),
        );
      });

      test('never disagrees with resolve', () {
        // The schedule exists so the widget does not have to re-derive the
        // bands. If the two ever parted company the widget would paint one
        // sky while the app named another — so this walks a single day minute
        // by minute and holds them to the same answer.
        final start = DateTime(2026, 8, 19, 5, 10); // this day's dawn opening
        const window = Duration(hours: 15, minutes: 55); // to its last band
        final schedule = SkyTime.scheduleFrom(
          start: start,
          window: window,
          days: [day],
        );

        for (var minute = 0; minute <= window.inMinutes; minute++) {
          final at = start.add(Duration(minutes: minute));
          expect(
            schedule.lastWhere((c) => !c.at.isAfter(at)).sky,
            SkyTime.resolve(now: at, sunrise: sunrise, sunset: sunset),
            reason: 'at $at',
          );
        }
      });

      test('the hour before sunrise belongs to the day about to start', () {
        // The obvious governing-sun rule — the last day to have risen — reads
        // this moment against yesterday's sunset and calls it night, and the
        // dawn band never appears at all.
        final schedule = SkyTime.scheduleFrom(
          start: DateTime(2026, 8, 20, 5, 20), // an hour before tomorrow rises
          window: const Duration(hours: 1),
          days: [day, tomorrow],
        );

        expect(schedule.single.sky, SkyTime.dawn);
      });

      test('evening survives having tomorrow to compare against', () {
        // Caught on a real device, not here: by late afternoon the *next*
        // day's sunrise is nearer than this one's, so a governing-sun rule
        // that measures to the nearest sunrise reads the evening against a
        // sun that has not come up yet and calls it night. The band vanished
        // from the published schedule entirely — morning, afternoon, night.
        final schedule = SkyTime.scheduleFrom(
          start: DateTime(2026, 8, 19, 12),
          window: const Duration(hours: 12),
          days: [day, tomorrow],
        );

        // Noon on the clock is still morning here — the sun peaks at 13:07.
        expect(schedule.map((c) => c.sky), [
          SkyTime.morning,
          SkyTime.afternoon,
          SkyTime.evening,
          SkyTime.night,
        ]);
        expect(schedule[2].at, sunset.subtract(const Duration(minutes: 90)));
      });

      test('every band appears across a full day with neighbours', () {
        // The whole run, with a day either side so the governing-sun choice
        // is under real pressure at both ends.
        final yesterday = SunDay(
          sunrise: DateTime(2026, 8, 18, 6, 0),
          sunset: DateTime(2026, 8, 18, 20, 15),
        );
        final schedule = SkyTime.scheduleFrom(
          start: DateTime(2026, 8, 19, 0),
          window: const Duration(hours: 24),
          days: [yesterday, day, tomorrow],
        );

        expect(schedule.map((c) => c.sky), [
          SkyTime.night,
          SkyTime.dawn,
          SkyTime.morning,
          SkyTime.afternoon,
          SkyTime.evening,
          SkyTime.night,
        ]);
      });

      test('a polar day collapses to the bands that actually happen', () {
        // Reykjavík in June: sunset lands on the following date and the
        // night band never opens. Every entry still has to be a real change
        // — a boundary that changes nothing earns no entry.
        final schedule = SkyTime.scheduleFrom(
          start: DateTime(2026, 6, 21, 2),
          window: const Duration(hours: 20),
          days: [
            SunDay(
              sunrise: DateTime(2026, 6, 21, 2, 55),
              sunset: DateTime(2026, 6, 22, 0, 3),
            ),
          ],
        );

        expect(schedule.first.sky, SkyTime.dawn);
        expect(schedule.map((c) => c.sky).toSet().length, schedule.length);
        for (var i = 1; i < schedule.length; i++) {
          expect(schedule[i].at.isAfter(schedule[i - 1].at), isTrue);
        }
      });

      test('no sun to go on is no schedule at all', () {
        expect(
          SkyTime.scheduleFrom(
            start: DateTime(2026, 8, 19, 14),
            window: const Duration(hours: 12),
            days: const [],
          ),
          isEmpty,
        );
      });
    });

    test('dawn, evening and night take white copy', () {
      expect(SkyTime.dawn.isDark, isTrue);
      expect(SkyTime.evening.isDark, isTrue);
      expect(SkyTime.night.isDark, isTrue);
      expect(SkyTime.morning.isDark, isFalse);
      expect(SkyTime.afternoon.isDark, isFalse);
    });
  });

  group('WidgetSnapshot', () {
    late Forecast forecast;

    setUp(() async {
      Forecast.clock = () => DateTime.utc(2026, 8, 19, 14, 14);
      addTearDown(() => Forecast.clock = DateTime.now);
      forecast = await FakeWeatherRepository().fetchForecast(
        FakeWeatherRepository.savedFixtures.first,
      );
    });

    test('formats the reading the way the widget prints it', () {
      final snapshot = WidgetSnapshot.of(
        forecast,
        const UnitFormatter(AppSettings()),
      );

      expect(snapshot.condition, WeatherCondition.clear);
      expect(snapshot.temperature, '22°');
      expect(snapshot.humidity, '58%');
      // The sky the widget opens on is the schedule's first entry, which
      // stands until the next change.
      expect(snapshot.skySchedule.first.sky, SkyTime.afternoon);
    });

    test('crosses to the native side already in the user unit', () {
      final snapshot = WidgetSnapshot.of(
        forecast,
        const UnitFormatter(
          AppSettings(temperatureUnit: TemperatureUnit.fahrenheit),
        ),
      );

      // The extensions have no access to the app's settings, so the number
      // has to arrive converted rather than converted at the far end.
      expect(snapshot.toStore()['temperature'], '72°');
      expect(snapshot.toStore()['condition'], 'clear');
    });

    test('sends exactly the keys the two native sides read', () {
      // Both extensions read this map by string key, in another process, and
      // a key that quietly changes name does not fail — it falls back to a
      // default and the tile goes on looking plausible. Renaming one means
      // changing `WidgetReading` in Swift and in Kotlin to match.
      expect(
        WidgetSnapshot.of(
          forecast,
          const UnitFormatter(AppSettings()),
        ).toStore().keys.toSet(),
        {
          'condition',
          'conditionLabel',
          'temperature',
          'humidity',
          'place',
          'utcOffsetMinutes',
          'skySchedule',
          'updatedAt',
        },
      );
    });

    test('sends the time of day as ingredients, not as answers', () {
      final store = WidgetSnapshot.of(
        forecast,
        const UnitFormatter(AppSettings()),
      ).toStore();

      // Nothing resolved against "now" may cross: the widget reads this hours
      // later and has to arrive at its own answer. See [WidgetSnapshot].
      expect(store.containsKey('clock'), isFalse);
      expect(store.containsKey('sky'), isFalse);
      expect(store.containsKey('caption'), isFalse);

      expect(store['skySchedule'], contains(':afternoon'));
      expect(RegExp(r'^\d+:afternoon').hasMatch(store['skySchedule']!), isTrue);
    });

    test('instants cross as absolute time, not as the place\'s wall clock', () {
      // The stamps the API returns are naive readings of the clock *there*.
      // Sent as-is, a phone in another zone would read them against its own
      // clock and land hours out — so they are pulled back through the
      // offset first. Tokyo is the case the fixture cannot show: its
      // offset is zero.
      final snapshot = WidgetSnapshot(
        condition: WeatherCondition.clear,
        temperature: '22°',
        humidity: '58%',
        place: 'Tokyo',
        utcOffset: const Duration(hours: 9),
        skySchedule: const [],
        // Noon on the wall in Tokyo is 03:00 UTC.
        updatedAt: DateTime(2026, 8, 19, 12),
      );

      expect(
        int.parse(snapshot.toStore()['updatedAt']!),
        DateTime.utc(2026, 8, 19, 3).millisecondsSinceEpoch ~/ 1000,
      );
      // And the offset goes over too, so the widget can put the instant back
      // on the clock it was read from — 12:00 in Tokyo, not 03:00.
      expect(snapshot.toStore()['utcOffsetMinutes'], '540');
    });
  });
}
