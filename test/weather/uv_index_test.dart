import 'package:atmos_flow/features/weather/domain/forecast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('uvBandOf', () {
    test('follows the WHO bands', () {
      expect(uvBandOf(0), 'Low');
      expect(uvBandOf(2.9), 'Low');
      expect(uvBandOf(3), 'Moderate');
      expect(uvBandOf(5), 'Moderate'); // the design's "5 · Moderate"
      expect(uvBandOf(6), 'High');
      expect(uvBandOf(8), 'Very high');
      expect(uvBandOf(11), 'Extreme');
      expect(uvBandOf(14), 'Extreme');
    });
  });

  group('uvFractionOf', () {
    test('clamps to the 0–11 scale', () {
      expect(uvFractionOf(0), 0);
      expect(uvFractionOf(11), 1);
      expect(uvFractionOf(20), 1);
      expect(uvFractionOf(5.5), closeTo(0.5, 0.001));
    });
  });
}
