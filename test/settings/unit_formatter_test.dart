import 'package:atmos_flow/features/settings/application/unit_formatter.dart';
import 'package:atmos_flow/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitFormatter', () {
    test('celsius is the default and renders a bare degree sign', () {
      const f = UnitFormatter(AppSettings());
      expect(f.temperature(22), '22°');
      expect(f.temperature(-4.4), '-4°');
    });

    test('fahrenheit converts and rounds', () {
      const f = UnitFormatter(
        AppSettings(temperatureUnit: TemperatureUnit.fahrenheit),
      );
      expect(f.temperature(0), '32°');
      expect(f.temperature(22), '72°');
      expect(f.temperature(100), '212°');
    });

    test('wind converts km/h to mph', () {
      const kmh = UnitFormatter(AppSettings());
      const mph = UnitFormatter(AppSettings(windUnit: WindUnit.mph));
      expect(kmh.wind(12), '12 km/h');
      expect(mph.wind(12), '7 mph');
    });

    test('visibility and pressure keep their metric units', () {
      const f = UnitFormatter(AppSettings());
      expect(f.visibility(12000), '12 km');
      expect(f.pressure(1014.9), '1015 hPa');
      expect(f.humidity(58), '58%');
    });
  });
}
