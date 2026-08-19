// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  temperatureUnit:
      $enumDecodeNullable(_$TemperatureUnitEnumMap, json['temperatureUnit']) ??
      TemperatureUnit.celsius,
  windUnit:
      $enumDecodeNullable(_$WindUnitEnumMap, json['windUnit']) ?? WindUnit.kmh,
  appearance:
      $enumDecodeNullable(_$AppearanceModeEnumMap, json['appearance']) ??
      AppearanceMode.auto,
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'temperatureUnit': _$TemperatureUnitEnumMap[instance.temperatureUnit]!,
      'windUnit': _$WindUnitEnumMap[instance.windUnit]!,
      'appearance': _$AppearanceModeEnumMap[instance.appearance]!,
    };

const _$TemperatureUnitEnumMap = {
  TemperatureUnit.celsius: 'celsius',
  TemperatureUnit.fahrenheit: 'fahrenheit',
};

const _$WindUnitEnumMap = {WindUnit.kmh: 'kmh', WindUnit.mph: 'mph'};

const _$AppearanceModeEnumMap = {
  AppearanceMode.auto: 'auto',
  AppearanceMode.light: 'light',
  AppearanceMode.dark: 'dark',
};
