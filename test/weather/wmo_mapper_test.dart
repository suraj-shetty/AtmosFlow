import 'package:atmos_flow/features/weather/data/wmo_mapper.dart';
import 'package:atmos_flow/features/weather/domain/weather_condition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WmoCodeMapper', () {
    const cases = <int, WeatherCondition>{
      0: WeatherCondition.clear,
      1: WeatherCondition.clear,
      2: WeatherCondition.cloudy,
      3: WeatherCondition.cloudy,
      45: WeatherCondition.fog,
      48: WeatherCondition.fog,
      51: WeatherCondition.drizzle,
      55: WeatherCondition.drizzle,
      56: WeatherCondition.drizzle,
      57: WeatherCondition.drizzle,
      61: WeatherCondition.rain,
      65: WeatherCondition.rain,
      66: WeatherCondition.rain,
      71: WeatherCondition.snow,
      75: WeatherCondition.snow,
      77: WeatherCondition.snow,
      80: WeatherCondition.rain,
      82: WeatherCondition.rain,
      85: WeatherCondition.snow,
      86: WeatherCondition.snow,
      95: WeatherCondition.storm,
      96: WeatherCondition.storm,
      99: WeatherCondition.storm,
    };

    cases.forEach((code, expected) {
      test('code $code maps to ${expected.name}', () {
        expect(WmoCodeMapper.toCondition(code), expected);
      });
    });

    test('unrecognised codes fall back to cloudy rather than throwing', () {
      expect(WmoCodeMapper.toCondition(4), WeatherCondition.cloudy);
      expect(WmoCodeMapper.toCondition(-1), WeatherCondition.cloudy);
      expect(WmoCodeMapper.toCondition(1000), WeatherCondition.cloudy);
    });

    test('every code 0–99 resolves to something', () {
      for (var code = 0; code <= 99; code++) {
        expect(WmoCodeMapper.toCondition(code), isA<WeatherCondition>());
      }
    });
  });
}
