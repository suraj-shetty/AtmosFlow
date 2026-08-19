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
      expect(snapshot.sky, SkyTime.afternoon);
      expect(snapshot.temperature, '22°');
      expect(snapshot.humidity, '58%');
      expect(snapshot.clock, '14:14');
      expect(snapshot.caption, 'Afternoon · Clear');
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
      expect(snapshot.toStore()['sky'], 'afternoon');
    });
  });
}
