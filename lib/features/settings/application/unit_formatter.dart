import '../domain/app_settings.dart';

/// Turns canonical domain values (°C, km/h, metres, hPa) into the strings the
/// design shows, honouring the user's unit choices.
///
/// Formatting lives here rather than in widgets so a unit change is one
/// dependency, and so the same "22°" appears everywhere it should.
class UnitFormatter {
  const UnitFormatter(this.settings);

  final AppSettings settings;

  /// "22°" — the degree sign without a unit letter, as the design shows it.
  String temperature(double celsius) => '${temperatureValue(celsius)}°';

  /// "22 °C" — used where the unit needs saying out loud (accessibility).
  String temperatureWithUnit(double celsius) =>
      '${temperatureValue(celsius)} ${settings.temperatureUnit.label}';

  int temperatureValue(double celsius) => switch (settings.temperatureUnit) {
    TemperatureUnit.celsius => celsius.round(),
    TemperatureUnit.fahrenheit => (celsius * 9 / 5 + 32).round(),
  };

  /// "12 km/h"
  String wind(double kmh) => '${windValue(kmh)} ${settings.windUnit.label}';

  int windValue(double kmh) => switch (settings.windUnit) {
    WindUnit.kmh => kmh.round(),
    WindUnit.mph => (kmh * 0.621371).round(),
  };

  /// "12 km" — visibility is always metric in the design.
  String visibility(double metres) => '${(metres / 1000).round()} km';

  String humidity(int percent) => '$percent%';

  String pressure(double hpa) => '${hpa.round()} hPa';
}
