import 'package:flutter/material.dart';
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

enum AppearanceMode {
  auto('Auto'),
  light('Light'),
  dark('Dark');

  const AppearanceMode(this.label);
  final String label;

  ThemeMode get themeMode => switch (this) {
    AppearanceMode.auto => ThemeMode.system,
    AppearanceMode.light => ThemeMode.light,
    AppearanceMode.dark => ThemeMode.dark,
  };
}

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(TemperatureUnit.celsius) TemperatureUnit temperatureUnit,
    @Default(WindUnit.kmh) WindUnit windUnit,
    @Default(AppearanceMode.auto) AppearanceMode appearance,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, Object?> json) =>
      _$AppSettingsFromJson(json);
}
