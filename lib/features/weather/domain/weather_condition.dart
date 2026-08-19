/// The seven conditions the design draws. Every WMO code the API returns is
/// collapsed into one of these by `WmoCodeMapper`.
enum WeatherCondition {
  clear('Clear'),
  cloudy('Cloudy'),
  fog('Fog'),
  drizzle('Drizzle'),
  rain('Rain'),
  snow('Snow'),
  storm('Storm');

  const WeatherCondition(this.label);

  /// The copy shown under the hero temperature.
  final String label;
}
