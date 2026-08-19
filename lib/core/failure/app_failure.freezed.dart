// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppFailure()';
}


}

/// @nodoc
class $AppFailureCopyWith<$Res>  {
$AppFailureCopyWith(AppFailure _, $Res Function(AppFailure) __);
}


/// Adds pattern-matching-related methods to [AppFailure].
extension AppFailurePatterns on AppFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NetworkFailure value)?  network,TResult Function( NotFoundFailure value)?  notFound,TResult Function( LocationDeniedFailure value)?  locationDenied,TResult Function( MalformedResponseFailure value)?  malformedResponse,TResult Function( UnknownFailure value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network(_that);case NotFoundFailure() when notFound != null:
return notFound(_that);case LocationDeniedFailure() when locationDenied != null:
return locationDenied(_that);case MalformedResponseFailure() when malformedResponse != null:
return malformedResponse(_that);case UnknownFailure() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NetworkFailure value)  network,required TResult Function( NotFoundFailure value)  notFound,required TResult Function( LocationDeniedFailure value)  locationDenied,required TResult Function( MalformedResponseFailure value)  malformedResponse,required TResult Function( UnknownFailure value)  unknown,}){
final _that = this;
switch (_that) {
case NetworkFailure():
return network(_that);case NotFoundFailure():
return notFound(_that);case LocationDeniedFailure():
return locationDenied(_that);case MalformedResponseFailure():
return malformedResponse(_that);case UnknownFailure():
return unknown(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NetworkFailure value)?  network,TResult? Function( NotFoundFailure value)?  notFound,TResult? Function( LocationDeniedFailure value)?  locationDenied,TResult? Function( MalformedResponseFailure value)?  malformedResponse,TResult? Function( UnknownFailure value)?  unknown,}){
final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network(_that);case NotFoundFailure() when notFound != null:
return notFound(_that);case LocationDeniedFailure() when locationDenied != null:
return locationDenied(_that);case MalformedResponseFailure() when malformedResponse != null:
return malformedResponse(_that);case UnknownFailure() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? detail)?  network,TResult Function( String? detail)?  notFound,TResult Function( bool permanently)?  locationDenied,TResult Function( String? detail)?  malformedResponse,TResult Function( String? detail)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network(_that.detail);case NotFoundFailure() when notFound != null:
return notFound(_that.detail);case LocationDeniedFailure() when locationDenied != null:
return locationDenied(_that.permanently);case MalformedResponseFailure() when malformedResponse != null:
return malformedResponse(_that.detail);case UnknownFailure() when unknown != null:
return unknown(_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? detail)  network,required TResult Function( String? detail)  notFound,required TResult Function( bool permanently)  locationDenied,required TResult Function( String? detail)  malformedResponse,required TResult Function( String? detail)  unknown,}) {final _that = this;
switch (_that) {
case NetworkFailure():
return network(_that.detail);case NotFoundFailure():
return notFound(_that.detail);case LocationDeniedFailure():
return locationDenied(_that.permanently);case MalformedResponseFailure():
return malformedResponse(_that.detail);case UnknownFailure():
return unknown(_that.detail);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? detail)?  network,TResult? Function( String? detail)?  notFound,TResult? Function( bool permanently)?  locationDenied,TResult? Function( String? detail)?  malformedResponse,TResult? Function( String? detail)?  unknown,}) {final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network(_that.detail);case NotFoundFailure() when notFound != null:
return notFound(_that.detail);case LocationDeniedFailure() when locationDenied != null:
return locationDenied(_that.permanently);case MalformedResponseFailure() when malformedResponse != null:
return malformedResponse(_that.detail);case UnknownFailure() when unknown != null:
return unknown(_that.detail);case _:
  return null;

}
}

}

/// @nodoc


class NetworkFailure extends AppFailure {
  const NetworkFailure({this.detail}): super._();
  

 final  String? detail;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkFailureCopyWith<NetworkFailure> get copyWith => _$NetworkFailureCopyWithImpl<NetworkFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkFailure&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'AppFailure.network(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $NetworkFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory $NetworkFailureCopyWith(NetworkFailure value, $Res Function(NetworkFailure) _then) = _$NetworkFailureCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$NetworkFailureCopyWithImpl<$Res>
    implements $NetworkFailureCopyWith<$Res> {
  _$NetworkFailureCopyWithImpl(this._self, this._then);

  final NetworkFailure _self;
  final $Res Function(NetworkFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(NetworkFailure(
detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class NotFoundFailure extends AppFailure {
  const NotFoundFailure({this.detail}): super._();
  

 final  String? detail;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotFoundFailureCopyWith<NotFoundFailure> get copyWith => _$NotFoundFailureCopyWithImpl<NotFoundFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotFoundFailure&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'AppFailure.notFound(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $NotFoundFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory $NotFoundFailureCopyWith(NotFoundFailure value, $Res Function(NotFoundFailure) _then) = _$NotFoundFailureCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$NotFoundFailureCopyWithImpl<$Res>
    implements $NotFoundFailureCopyWith<$Res> {
  _$NotFoundFailureCopyWithImpl(this._self, this._then);

  final NotFoundFailure _self;
  final $Res Function(NotFoundFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(NotFoundFailure(
detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class LocationDeniedFailure extends AppFailure {
  const LocationDeniedFailure({this.permanently = false}): super._();
  

@JsonKey() final  bool permanently;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationDeniedFailureCopyWith<LocationDeniedFailure> get copyWith => _$LocationDeniedFailureCopyWithImpl<LocationDeniedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationDeniedFailure&&(identical(other.permanently, permanently) || other.permanently == permanently));
}


@override
int get hashCode => Object.hash(runtimeType,permanently);

@override
String toString() {
  return 'AppFailure.locationDenied(permanently: $permanently)';
}


}

/// @nodoc
abstract mixin class $LocationDeniedFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory $LocationDeniedFailureCopyWith(LocationDeniedFailure value, $Res Function(LocationDeniedFailure) _then) = _$LocationDeniedFailureCopyWithImpl;
@useResult
$Res call({
 bool permanently
});




}
/// @nodoc
class _$LocationDeniedFailureCopyWithImpl<$Res>
    implements $LocationDeniedFailureCopyWith<$Res> {
  _$LocationDeniedFailureCopyWithImpl(this._self, this._then);

  final LocationDeniedFailure _self;
  final $Res Function(LocationDeniedFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? permanently = null,}) {
  return _then(LocationDeniedFailure(
permanently: null == permanently ? _self.permanently : permanently // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class MalformedResponseFailure extends AppFailure {
  const MalformedResponseFailure({this.detail}): super._();
  

 final  String? detail;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MalformedResponseFailureCopyWith<MalformedResponseFailure> get copyWith => _$MalformedResponseFailureCopyWithImpl<MalformedResponseFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MalformedResponseFailure&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'AppFailure.malformedResponse(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $MalformedResponseFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory $MalformedResponseFailureCopyWith(MalformedResponseFailure value, $Res Function(MalformedResponseFailure) _then) = _$MalformedResponseFailureCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$MalformedResponseFailureCopyWithImpl<$Res>
    implements $MalformedResponseFailureCopyWith<$Res> {
  _$MalformedResponseFailureCopyWithImpl(this._self, this._then);

  final MalformedResponseFailure _self;
  final $Res Function(MalformedResponseFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(MalformedResponseFailure(
detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class UnknownFailure extends AppFailure {
  const UnknownFailure({this.detail}): super._();
  

 final  String? detail;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownFailureCopyWith<UnknownFailure> get copyWith => _$UnknownFailureCopyWithImpl<UnknownFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownFailure&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode => Object.hash(runtimeType,detail);

@override
String toString() {
  return 'AppFailure.unknown(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $UnknownFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory $UnknownFailureCopyWith(UnknownFailure value, $Res Function(UnknownFailure) _then) = _$UnknownFailureCopyWithImpl;
@useResult
$Res call({
 String? detail
});




}
/// @nodoc
class _$UnknownFailureCopyWithImpl<$Res>
    implements $UnknownFailureCopyWith<$Res> {
  _$UnknownFailureCopyWithImpl(this._self, this._then);

  final UnknownFailure _self;
  final $Res Function(UnknownFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(UnknownFailure(
detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
