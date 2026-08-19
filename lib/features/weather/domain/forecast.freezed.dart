// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forecast.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Forecast {

 Place get place; CurrentWeather get current; List<HourlyPoint> get hourly; List<DailyForecast> get daily; DateTime get fetchedAt;/// The place's offset from UTC, as the API reported it.
 Duration get utcOffset;
/// Create a copy of Forecast
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForecastCopyWith<Forecast> get copyWith => _$ForecastCopyWithImpl<Forecast>(this as Forecast, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Forecast&&(identical(other.place, place) || other.place == place)&&(identical(other.current, current) || other.current == current)&&const DeepCollectionEquality().equals(other.hourly, hourly)&&const DeepCollectionEquality().equals(other.daily, daily)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.utcOffset, utcOffset) || other.utcOffset == utcOffset));
}


@override
int get hashCode => Object.hash(runtimeType,place,current,const DeepCollectionEquality().hash(hourly),const DeepCollectionEquality().hash(daily),fetchedAt,utcOffset);

@override
String toString() {
  return 'Forecast(place: $place, current: $current, hourly: $hourly, daily: $daily, fetchedAt: $fetchedAt, utcOffset: $utcOffset)';
}


}

/// @nodoc
abstract mixin class $ForecastCopyWith<$Res>  {
  factory $ForecastCopyWith(Forecast value, $Res Function(Forecast) _then) = _$ForecastCopyWithImpl;
@useResult
$Res call({
 Place place, CurrentWeather current, List<HourlyPoint> hourly, List<DailyForecast> daily, DateTime fetchedAt, Duration utcOffset
});


$PlaceCopyWith<$Res> get place;$CurrentWeatherCopyWith<$Res> get current;

}
/// @nodoc
class _$ForecastCopyWithImpl<$Res>
    implements $ForecastCopyWith<$Res> {
  _$ForecastCopyWithImpl(this._self, this._then);

  final Forecast _self;
  final $Res Function(Forecast) _then;

/// Create a copy of Forecast
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? place = null,Object? current = null,Object? hourly = null,Object? daily = null,Object? fetchedAt = null,Object? utcOffset = null,}) {
  return _then(_self.copyWith(
place: null == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as Place,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as CurrentWeather,hourly: null == hourly ? _self.hourly : hourly // ignore: cast_nullable_to_non_nullable
as List<HourlyPoint>,daily: null == daily ? _self.daily : daily // ignore: cast_nullable_to_non_nullable
as List<DailyForecast>,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,utcOffset: null == utcOffset ? _self.utcOffset : utcOffset // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}
/// Create a copy of Forecast
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaceCopyWith<$Res> get place {
  
  return $PlaceCopyWith<$Res>(_self.place, (value) {
    return _then(_self.copyWith(place: value));
  });
}/// Create a copy of Forecast
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrentWeatherCopyWith<$Res> get current {
  
  return $CurrentWeatherCopyWith<$Res>(_self.current, (value) {
    return _then(_self.copyWith(current: value));
  });
}
}


/// Adds pattern-matching-related methods to [Forecast].
extension ForecastPatterns on Forecast {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Forecast value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Forecast() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Forecast value)  $default,){
final _that = this;
switch (_that) {
case _Forecast():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Forecast value)?  $default,){
final _that = this;
switch (_that) {
case _Forecast() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Place place,  CurrentWeather current,  List<HourlyPoint> hourly,  List<DailyForecast> daily,  DateTime fetchedAt,  Duration utcOffset)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Forecast() when $default != null:
return $default(_that.place,_that.current,_that.hourly,_that.daily,_that.fetchedAt,_that.utcOffset);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Place place,  CurrentWeather current,  List<HourlyPoint> hourly,  List<DailyForecast> daily,  DateTime fetchedAt,  Duration utcOffset)  $default,) {final _that = this;
switch (_that) {
case _Forecast():
return $default(_that.place,_that.current,_that.hourly,_that.daily,_that.fetchedAt,_that.utcOffset);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Place place,  CurrentWeather current,  List<HourlyPoint> hourly,  List<DailyForecast> daily,  DateTime fetchedAt,  Duration utcOffset)?  $default,) {final _that = this;
switch (_that) {
case _Forecast() when $default != null:
return $default(_that.place,_that.current,_that.hourly,_that.daily,_that.fetchedAt,_that.utcOffset);case _:
  return null;

}
}

}

/// @nodoc


class _Forecast extends Forecast {
  const _Forecast({required this.place, required this.current, required final  List<HourlyPoint> hourly, required final  List<DailyForecast> daily, required this.fetchedAt, required this.utcOffset}): _hourly = hourly,_daily = daily,super._();
  

@override final  Place place;
@override final  CurrentWeather current;
 final  List<HourlyPoint> _hourly;
@override List<HourlyPoint> get hourly {
  if (_hourly is EqualUnmodifiableListView) return _hourly;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hourly);
}

 final  List<DailyForecast> _daily;
@override List<DailyForecast> get daily {
  if (_daily is EqualUnmodifiableListView) return _daily;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_daily);
}

@override final  DateTime fetchedAt;
/// The place's offset from UTC, as the API reported it.
@override final  Duration utcOffset;

/// Create a copy of Forecast
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ForecastCopyWith<_Forecast> get copyWith => __$ForecastCopyWithImpl<_Forecast>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Forecast&&(identical(other.place, place) || other.place == place)&&(identical(other.current, current) || other.current == current)&&const DeepCollectionEquality().equals(other._hourly, _hourly)&&const DeepCollectionEquality().equals(other._daily, _daily)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.utcOffset, utcOffset) || other.utcOffset == utcOffset));
}


@override
int get hashCode => Object.hash(runtimeType,place,current,const DeepCollectionEquality().hash(_hourly),const DeepCollectionEquality().hash(_daily),fetchedAt,utcOffset);

@override
String toString() {
  return 'Forecast(place: $place, current: $current, hourly: $hourly, daily: $daily, fetchedAt: $fetchedAt, utcOffset: $utcOffset)';
}


}

/// @nodoc
abstract mixin class _$ForecastCopyWith<$Res> implements $ForecastCopyWith<$Res> {
  factory _$ForecastCopyWith(_Forecast value, $Res Function(_Forecast) _then) = __$ForecastCopyWithImpl;
@override @useResult
$Res call({
 Place place, CurrentWeather current, List<HourlyPoint> hourly, List<DailyForecast> daily, DateTime fetchedAt, Duration utcOffset
});


@override $PlaceCopyWith<$Res> get place;@override $CurrentWeatherCopyWith<$Res> get current;

}
/// @nodoc
class __$ForecastCopyWithImpl<$Res>
    implements _$ForecastCopyWith<$Res> {
  __$ForecastCopyWithImpl(this._self, this._then);

  final _Forecast _self;
  final $Res Function(_Forecast) _then;

/// Create a copy of Forecast
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? place = null,Object? current = null,Object? hourly = null,Object? daily = null,Object? fetchedAt = null,Object? utcOffset = null,}) {
  return _then(_Forecast(
place: null == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as Place,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as CurrentWeather,hourly: null == hourly ? _self._hourly : hourly // ignore: cast_nullable_to_non_nullable
as List<HourlyPoint>,daily: null == daily ? _self._daily : daily // ignore: cast_nullable_to_non_nullable
as List<DailyForecast>,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,utcOffset: null == utcOffset ? _self.utcOffset : utcOffset // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

/// Create a copy of Forecast
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaceCopyWith<$Res> get place {
  
  return $PlaceCopyWith<$Res>(_self.place, (value) {
    return _then(_self.copyWith(place: value));
  });
}/// Create a copy of Forecast
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrentWeatherCopyWith<$Res> get current {
  
  return $CurrentWeatherCopyWith<$Res>(_self.current, (value) {
    return _then(_self.copyWith(current: value));
  });
}
}

/// @nodoc
mixin _$CurrentWeather {

 double get temperature; double get feelsLike; WeatherCondition get condition; bool get isNight; int get humidity; double get windSpeed; int get windDirection; double get uvIndex; double get visibilityMetres; double get pressureHpa;
/// Create a copy of CurrentWeather
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CurrentWeatherCopyWith<CurrentWeather> get copyWith => _$CurrentWeatherCopyWithImpl<CurrentWeather>(this as CurrentWeather, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CurrentWeather&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.feelsLike, feelsLike) || other.feelsLike == feelsLike)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.isNight, isNight) || other.isNight == isNight)&&(identical(other.humidity, humidity) || other.humidity == humidity)&&(identical(other.windSpeed, windSpeed) || other.windSpeed == windSpeed)&&(identical(other.windDirection, windDirection) || other.windDirection == windDirection)&&(identical(other.uvIndex, uvIndex) || other.uvIndex == uvIndex)&&(identical(other.visibilityMetres, visibilityMetres) || other.visibilityMetres == visibilityMetres)&&(identical(other.pressureHpa, pressureHpa) || other.pressureHpa == pressureHpa));
}


@override
int get hashCode => Object.hash(runtimeType,temperature,feelsLike,condition,isNight,humidity,windSpeed,windDirection,uvIndex,visibilityMetres,pressureHpa);

@override
String toString() {
  return 'CurrentWeather(temperature: $temperature, feelsLike: $feelsLike, condition: $condition, isNight: $isNight, humidity: $humidity, windSpeed: $windSpeed, windDirection: $windDirection, uvIndex: $uvIndex, visibilityMetres: $visibilityMetres, pressureHpa: $pressureHpa)';
}


}

/// @nodoc
abstract mixin class $CurrentWeatherCopyWith<$Res>  {
  factory $CurrentWeatherCopyWith(CurrentWeather value, $Res Function(CurrentWeather) _then) = _$CurrentWeatherCopyWithImpl;
@useResult
$Res call({
 double temperature, double feelsLike, WeatherCondition condition, bool isNight, int humidity, double windSpeed, int windDirection, double uvIndex, double visibilityMetres, double pressureHpa
});




}
/// @nodoc
class _$CurrentWeatherCopyWithImpl<$Res>
    implements $CurrentWeatherCopyWith<$Res> {
  _$CurrentWeatherCopyWithImpl(this._self, this._then);

  final CurrentWeather _self;
  final $Res Function(CurrentWeather) _then;

/// Create a copy of CurrentWeather
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? temperature = null,Object? feelsLike = null,Object? condition = null,Object? isNight = null,Object? humidity = null,Object? windSpeed = null,Object? windDirection = null,Object? uvIndex = null,Object? visibilityMetres = null,Object? pressureHpa = null,}) {
  return _then(_self.copyWith(
temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double,feelsLike: null == feelsLike ? _self.feelsLike : feelsLike // ignore: cast_nullable_to_non_nullable
as double,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as WeatherCondition,isNight: null == isNight ? _self.isNight : isNight // ignore: cast_nullable_to_non_nullable
as bool,humidity: null == humidity ? _self.humidity : humidity // ignore: cast_nullable_to_non_nullable
as int,windSpeed: null == windSpeed ? _self.windSpeed : windSpeed // ignore: cast_nullable_to_non_nullable
as double,windDirection: null == windDirection ? _self.windDirection : windDirection // ignore: cast_nullable_to_non_nullable
as int,uvIndex: null == uvIndex ? _self.uvIndex : uvIndex // ignore: cast_nullable_to_non_nullable
as double,visibilityMetres: null == visibilityMetres ? _self.visibilityMetres : visibilityMetres // ignore: cast_nullable_to_non_nullable
as double,pressureHpa: null == pressureHpa ? _self.pressureHpa : pressureHpa // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CurrentWeather].
extension CurrentWeatherPatterns on CurrentWeather {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CurrentWeather value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CurrentWeather() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CurrentWeather value)  $default,){
final _that = this;
switch (_that) {
case _CurrentWeather():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CurrentWeather value)?  $default,){
final _that = this;
switch (_that) {
case _CurrentWeather() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double temperature,  double feelsLike,  WeatherCondition condition,  bool isNight,  int humidity,  double windSpeed,  int windDirection,  double uvIndex,  double visibilityMetres,  double pressureHpa)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CurrentWeather() when $default != null:
return $default(_that.temperature,_that.feelsLike,_that.condition,_that.isNight,_that.humidity,_that.windSpeed,_that.windDirection,_that.uvIndex,_that.visibilityMetres,_that.pressureHpa);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double temperature,  double feelsLike,  WeatherCondition condition,  bool isNight,  int humidity,  double windSpeed,  int windDirection,  double uvIndex,  double visibilityMetres,  double pressureHpa)  $default,) {final _that = this;
switch (_that) {
case _CurrentWeather():
return $default(_that.temperature,_that.feelsLike,_that.condition,_that.isNight,_that.humidity,_that.windSpeed,_that.windDirection,_that.uvIndex,_that.visibilityMetres,_that.pressureHpa);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double temperature,  double feelsLike,  WeatherCondition condition,  bool isNight,  int humidity,  double windSpeed,  int windDirection,  double uvIndex,  double visibilityMetres,  double pressureHpa)?  $default,) {final _that = this;
switch (_that) {
case _CurrentWeather() when $default != null:
return $default(_that.temperature,_that.feelsLike,_that.condition,_that.isNight,_that.humidity,_that.windSpeed,_that.windDirection,_that.uvIndex,_that.visibilityMetres,_that.pressureHpa);case _:
  return null;

}
}

}

/// @nodoc


class _CurrentWeather extends CurrentWeather {
  const _CurrentWeather({required this.temperature, required this.feelsLike, required this.condition, required this.isNight, required this.humidity, required this.windSpeed, required this.windDirection, required this.uvIndex, required this.visibilityMetres, required this.pressureHpa}): super._();
  

@override final  double temperature;
@override final  double feelsLike;
@override final  WeatherCondition condition;
@override final  bool isNight;
@override final  int humidity;
@override final  double windSpeed;
@override final  int windDirection;
@override final  double uvIndex;
@override final  double visibilityMetres;
@override final  double pressureHpa;

/// Create a copy of CurrentWeather
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CurrentWeatherCopyWith<_CurrentWeather> get copyWith => __$CurrentWeatherCopyWithImpl<_CurrentWeather>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CurrentWeather&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.feelsLike, feelsLike) || other.feelsLike == feelsLike)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.isNight, isNight) || other.isNight == isNight)&&(identical(other.humidity, humidity) || other.humidity == humidity)&&(identical(other.windSpeed, windSpeed) || other.windSpeed == windSpeed)&&(identical(other.windDirection, windDirection) || other.windDirection == windDirection)&&(identical(other.uvIndex, uvIndex) || other.uvIndex == uvIndex)&&(identical(other.visibilityMetres, visibilityMetres) || other.visibilityMetres == visibilityMetres)&&(identical(other.pressureHpa, pressureHpa) || other.pressureHpa == pressureHpa));
}


@override
int get hashCode => Object.hash(runtimeType,temperature,feelsLike,condition,isNight,humidity,windSpeed,windDirection,uvIndex,visibilityMetres,pressureHpa);

@override
String toString() {
  return 'CurrentWeather(temperature: $temperature, feelsLike: $feelsLike, condition: $condition, isNight: $isNight, humidity: $humidity, windSpeed: $windSpeed, windDirection: $windDirection, uvIndex: $uvIndex, visibilityMetres: $visibilityMetres, pressureHpa: $pressureHpa)';
}


}

/// @nodoc
abstract mixin class _$CurrentWeatherCopyWith<$Res> implements $CurrentWeatherCopyWith<$Res> {
  factory _$CurrentWeatherCopyWith(_CurrentWeather value, $Res Function(_CurrentWeather) _then) = __$CurrentWeatherCopyWithImpl;
@override @useResult
$Res call({
 double temperature, double feelsLike, WeatherCondition condition, bool isNight, int humidity, double windSpeed, int windDirection, double uvIndex, double visibilityMetres, double pressureHpa
});




}
/// @nodoc
class __$CurrentWeatherCopyWithImpl<$Res>
    implements _$CurrentWeatherCopyWith<$Res> {
  __$CurrentWeatherCopyWithImpl(this._self, this._then);

  final _CurrentWeather _self;
  final $Res Function(_CurrentWeather) _then;

/// Create a copy of CurrentWeather
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? temperature = null,Object? feelsLike = null,Object? condition = null,Object? isNight = null,Object? humidity = null,Object? windSpeed = null,Object? windDirection = null,Object? uvIndex = null,Object? visibilityMetres = null,Object? pressureHpa = null,}) {
  return _then(_CurrentWeather(
temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double,feelsLike: null == feelsLike ? _self.feelsLike : feelsLike // ignore: cast_nullable_to_non_nullable
as double,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as WeatherCondition,isNight: null == isNight ? _self.isNight : isNight // ignore: cast_nullable_to_non_nullable
as bool,humidity: null == humidity ? _self.humidity : humidity // ignore: cast_nullable_to_non_nullable
as int,windSpeed: null == windSpeed ? _self.windSpeed : windSpeed // ignore: cast_nullable_to_non_nullable
as double,windDirection: null == windDirection ? _self.windDirection : windDirection // ignore: cast_nullable_to_non_nullable
as int,uvIndex: null == uvIndex ? _self.uvIndex : uvIndex // ignore: cast_nullable_to_non_nullable
as double,visibilityMetres: null == visibilityMetres ? _self.visibilityMetres : visibilityMetres // ignore: cast_nullable_to_non_nullable
as double,pressureHpa: null == pressureHpa ? _self.pressureHpa : pressureHpa // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$HourlyPoint {

 DateTime get time; double get temperature; WeatherCondition get condition; bool get isNight; int get precipitationProbability;
/// Create a copy of HourlyPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HourlyPointCopyWith<HourlyPoint> get copyWith => _$HourlyPointCopyWithImpl<HourlyPoint>(this as HourlyPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HourlyPoint&&(identical(other.time, time) || other.time == time)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.isNight, isNight) || other.isNight == isNight)&&(identical(other.precipitationProbability, precipitationProbability) || other.precipitationProbability == precipitationProbability));
}


@override
int get hashCode => Object.hash(runtimeType,time,temperature,condition,isNight,precipitationProbability);

@override
String toString() {
  return 'HourlyPoint(time: $time, temperature: $temperature, condition: $condition, isNight: $isNight, precipitationProbability: $precipitationProbability)';
}


}

/// @nodoc
abstract mixin class $HourlyPointCopyWith<$Res>  {
  factory $HourlyPointCopyWith(HourlyPoint value, $Res Function(HourlyPoint) _then) = _$HourlyPointCopyWithImpl;
@useResult
$Res call({
 DateTime time, double temperature, WeatherCondition condition, bool isNight, int precipitationProbability
});




}
/// @nodoc
class _$HourlyPointCopyWithImpl<$Res>
    implements $HourlyPointCopyWith<$Res> {
  _$HourlyPointCopyWithImpl(this._self, this._then);

  final HourlyPoint _self;
  final $Res Function(HourlyPoint) _then;

/// Create a copy of HourlyPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? time = null,Object? temperature = null,Object? condition = null,Object? isNight = null,Object? precipitationProbability = null,}) {
  return _then(_self.copyWith(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as WeatherCondition,isNight: null == isNight ? _self.isNight : isNight // ignore: cast_nullable_to_non_nullable
as bool,precipitationProbability: null == precipitationProbability ? _self.precipitationProbability : precipitationProbability // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [HourlyPoint].
extension HourlyPointPatterns on HourlyPoint {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HourlyPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HourlyPoint() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HourlyPoint value)  $default,){
final _that = this;
switch (_that) {
case _HourlyPoint():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HourlyPoint value)?  $default,){
final _that = this;
switch (_that) {
case _HourlyPoint() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime time,  double temperature,  WeatherCondition condition,  bool isNight,  int precipitationProbability)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HourlyPoint() when $default != null:
return $default(_that.time,_that.temperature,_that.condition,_that.isNight,_that.precipitationProbability);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime time,  double temperature,  WeatherCondition condition,  bool isNight,  int precipitationProbability)  $default,) {final _that = this;
switch (_that) {
case _HourlyPoint():
return $default(_that.time,_that.temperature,_that.condition,_that.isNight,_that.precipitationProbability);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime time,  double temperature,  WeatherCondition condition,  bool isNight,  int precipitationProbability)?  $default,) {final _that = this;
switch (_that) {
case _HourlyPoint() when $default != null:
return $default(_that.time,_that.temperature,_that.condition,_that.isNight,_that.precipitationProbability);case _:
  return null;

}
}

}

/// @nodoc


class _HourlyPoint implements HourlyPoint {
  const _HourlyPoint({required this.time, required this.temperature, required this.condition, required this.isNight, required this.precipitationProbability});
  

@override final  DateTime time;
@override final  double temperature;
@override final  WeatherCondition condition;
@override final  bool isNight;
@override final  int precipitationProbability;

/// Create a copy of HourlyPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HourlyPointCopyWith<_HourlyPoint> get copyWith => __$HourlyPointCopyWithImpl<_HourlyPoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HourlyPoint&&(identical(other.time, time) || other.time == time)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.isNight, isNight) || other.isNight == isNight)&&(identical(other.precipitationProbability, precipitationProbability) || other.precipitationProbability == precipitationProbability));
}


@override
int get hashCode => Object.hash(runtimeType,time,temperature,condition,isNight,precipitationProbability);

@override
String toString() {
  return 'HourlyPoint(time: $time, temperature: $temperature, condition: $condition, isNight: $isNight, precipitationProbability: $precipitationProbability)';
}


}

/// @nodoc
abstract mixin class _$HourlyPointCopyWith<$Res> implements $HourlyPointCopyWith<$Res> {
  factory _$HourlyPointCopyWith(_HourlyPoint value, $Res Function(_HourlyPoint) _then) = __$HourlyPointCopyWithImpl;
@override @useResult
$Res call({
 DateTime time, double temperature, WeatherCondition condition, bool isNight, int precipitationProbability
});




}
/// @nodoc
class __$HourlyPointCopyWithImpl<$Res>
    implements _$HourlyPointCopyWith<$Res> {
  __$HourlyPointCopyWithImpl(this._self, this._then);

  final _HourlyPoint _self;
  final $Res Function(_HourlyPoint) _then;

/// Create a copy of HourlyPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? time = null,Object? temperature = null,Object? condition = null,Object? isNight = null,Object? precipitationProbability = null,}) {
  return _then(_HourlyPoint(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as WeatherCondition,isNight: null == isNight ? _self.isNight : isNight // ignore: cast_nullable_to_non_nullable
as bool,precipitationProbability: null == precipitationProbability ? _self.precipitationProbability : precipitationProbability // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$DailyForecast {

 DateTime get date; double get high; double get low; WeatherCondition get condition; DateTime get sunrise; DateTime get sunset; double get uvIndexMax;/// 24 hourly temperatures, midnight to 11PM — the Day Detail line chart.
 List<double> get hourlyTemperatures;
/// Create a copy of DailyForecast
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyForecastCopyWith<DailyForecast> get copyWith => _$DailyForecastCopyWithImpl<DailyForecast>(this as DailyForecast, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyForecast&&(identical(other.date, date) || other.date == date)&&(identical(other.high, high) || other.high == high)&&(identical(other.low, low) || other.low == low)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.sunrise, sunrise) || other.sunrise == sunrise)&&(identical(other.sunset, sunset) || other.sunset == sunset)&&(identical(other.uvIndexMax, uvIndexMax) || other.uvIndexMax == uvIndexMax)&&const DeepCollectionEquality().equals(other.hourlyTemperatures, hourlyTemperatures));
}


@override
int get hashCode => Object.hash(runtimeType,date,high,low,condition,sunrise,sunset,uvIndexMax,const DeepCollectionEquality().hash(hourlyTemperatures));

@override
String toString() {
  return 'DailyForecast(date: $date, high: $high, low: $low, condition: $condition, sunrise: $sunrise, sunset: $sunset, uvIndexMax: $uvIndexMax, hourlyTemperatures: $hourlyTemperatures)';
}


}

/// @nodoc
abstract mixin class $DailyForecastCopyWith<$Res>  {
  factory $DailyForecastCopyWith(DailyForecast value, $Res Function(DailyForecast) _then) = _$DailyForecastCopyWithImpl;
@useResult
$Res call({
 DateTime date, double high, double low, WeatherCondition condition, DateTime sunrise, DateTime sunset, double uvIndexMax, List<double> hourlyTemperatures
});




}
/// @nodoc
class _$DailyForecastCopyWithImpl<$Res>
    implements $DailyForecastCopyWith<$Res> {
  _$DailyForecastCopyWithImpl(this._self, this._then);

  final DailyForecast _self;
  final $Res Function(DailyForecast) _then;

/// Create a copy of DailyForecast
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? high = null,Object? low = null,Object? condition = null,Object? sunrise = null,Object? sunset = null,Object? uvIndexMax = null,Object? hourlyTemperatures = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as double,low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as double,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as WeatherCondition,sunrise: null == sunrise ? _self.sunrise : sunrise // ignore: cast_nullable_to_non_nullable
as DateTime,sunset: null == sunset ? _self.sunset : sunset // ignore: cast_nullable_to_non_nullable
as DateTime,uvIndexMax: null == uvIndexMax ? _self.uvIndexMax : uvIndexMax // ignore: cast_nullable_to_non_nullable
as double,hourlyTemperatures: null == hourlyTemperatures ? _self.hourlyTemperatures : hourlyTemperatures // ignore: cast_nullable_to_non_nullable
as List<double>,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyForecast].
extension DailyForecastPatterns on DailyForecast {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyForecast value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyForecast() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyForecast value)  $default,){
final _that = this;
switch (_that) {
case _DailyForecast():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyForecast value)?  $default,){
final _that = this;
switch (_that) {
case _DailyForecast() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  double high,  double low,  WeatherCondition condition,  DateTime sunrise,  DateTime sunset,  double uvIndexMax,  List<double> hourlyTemperatures)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyForecast() when $default != null:
return $default(_that.date,_that.high,_that.low,_that.condition,_that.sunrise,_that.sunset,_that.uvIndexMax,_that.hourlyTemperatures);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  double high,  double low,  WeatherCondition condition,  DateTime sunrise,  DateTime sunset,  double uvIndexMax,  List<double> hourlyTemperatures)  $default,) {final _that = this;
switch (_that) {
case _DailyForecast():
return $default(_that.date,_that.high,_that.low,_that.condition,_that.sunrise,_that.sunset,_that.uvIndexMax,_that.hourlyTemperatures);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  double high,  double low,  WeatherCondition condition,  DateTime sunrise,  DateTime sunset,  double uvIndexMax,  List<double> hourlyTemperatures)?  $default,) {final _that = this;
switch (_that) {
case _DailyForecast() when $default != null:
return $default(_that.date,_that.high,_that.low,_that.condition,_that.sunrise,_that.sunset,_that.uvIndexMax,_that.hourlyTemperatures);case _:
  return null;

}
}

}

/// @nodoc


class _DailyForecast extends DailyForecast {
  const _DailyForecast({required this.date, required this.high, required this.low, required this.condition, required this.sunrise, required this.sunset, required this.uvIndexMax, required final  List<double> hourlyTemperatures}): _hourlyTemperatures = hourlyTemperatures,super._();
  

@override final  DateTime date;
@override final  double high;
@override final  double low;
@override final  WeatherCondition condition;
@override final  DateTime sunrise;
@override final  DateTime sunset;
@override final  double uvIndexMax;
/// 24 hourly temperatures, midnight to 11PM — the Day Detail line chart.
 final  List<double> _hourlyTemperatures;
/// 24 hourly temperatures, midnight to 11PM — the Day Detail line chart.
@override List<double> get hourlyTemperatures {
  if (_hourlyTemperatures is EqualUnmodifiableListView) return _hourlyTemperatures;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hourlyTemperatures);
}


/// Create a copy of DailyForecast
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyForecastCopyWith<_DailyForecast> get copyWith => __$DailyForecastCopyWithImpl<_DailyForecast>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyForecast&&(identical(other.date, date) || other.date == date)&&(identical(other.high, high) || other.high == high)&&(identical(other.low, low) || other.low == low)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.sunrise, sunrise) || other.sunrise == sunrise)&&(identical(other.sunset, sunset) || other.sunset == sunset)&&(identical(other.uvIndexMax, uvIndexMax) || other.uvIndexMax == uvIndexMax)&&const DeepCollectionEquality().equals(other._hourlyTemperatures, _hourlyTemperatures));
}


@override
int get hashCode => Object.hash(runtimeType,date,high,low,condition,sunrise,sunset,uvIndexMax,const DeepCollectionEquality().hash(_hourlyTemperatures));

@override
String toString() {
  return 'DailyForecast(date: $date, high: $high, low: $low, condition: $condition, sunrise: $sunrise, sunset: $sunset, uvIndexMax: $uvIndexMax, hourlyTemperatures: $hourlyTemperatures)';
}


}

/// @nodoc
abstract mixin class _$DailyForecastCopyWith<$Res> implements $DailyForecastCopyWith<$Res> {
  factory _$DailyForecastCopyWith(_DailyForecast value, $Res Function(_DailyForecast) _then) = __$DailyForecastCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, double high, double low, WeatherCondition condition, DateTime sunrise, DateTime sunset, double uvIndexMax, List<double> hourlyTemperatures
});




}
/// @nodoc
class __$DailyForecastCopyWithImpl<$Res>
    implements _$DailyForecastCopyWith<$Res> {
  __$DailyForecastCopyWithImpl(this._self, this._then);

  final _DailyForecast _self;
  final $Res Function(_DailyForecast) _then;

/// Create a copy of DailyForecast
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? high = null,Object? low = null,Object? condition = null,Object? sunrise = null,Object? sunset = null,Object? uvIndexMax = null,Object? hourlyTemperatures = null,}) {
  return _then(_DailyForecast(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as double,low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as double,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as WeatherCondition,sunrise: null == sunrise ? _self.sunrise : sunrise // ignore: cast_nullable_to_non_nullable
as DateTime,sunset: null == sunset ? _self.sunset : sunset // ignore: cast_nullable_to_non_nullable
as DateTime,uvIndexMax: null == uvIndexMax ? _self.uvIndexMax : uvIndexMax // ignore: cast_nullable_to_non_nullable
as double,hourlyTemperatures: null == hourlyTemperatures ? _self._hourlyTemperatures : hourlyTemperatures // ignore: cast_nullable_to_non_nullable
as List<double>,
  ));
}


}

// dart format on
