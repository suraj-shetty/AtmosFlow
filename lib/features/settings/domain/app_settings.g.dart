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
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'temperatureUnit': _$TemperatureUnitEnumMap[instance.temperatureUnit]!,
      'windUnit': _$WindUnitEnumMap[instance.windUnit]!,
    };

const _$TemperatureUnitEnumMap = {
  TemperatureUnit.celsius: 'celsius',
  TemperatureUnit.fahrenheit: 'fahrenheit',
};

const _$WindUnitEnumMap = {WindUnit.kmh: 'kmh', WindUnit.mph: 'mph'};
