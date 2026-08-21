import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

enum TemperatureUnit {
  celsius('°C'),
  fahrenheit('°F');

  const TemperatureUnit(this.label);
  final String label;
}

enum WindUnit {
  kmh('km/h'),
  mph('mph');

  const WindUnit(this.label);
  final String label;
}

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(TemperatureUnit.celsius) TemperatureUnit temperatureUnit,
    @Default(WindUnit.kmh) WindUnit windUnit,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, Object?> json) =>
      _$AppSettingsFromJson(json);
}
