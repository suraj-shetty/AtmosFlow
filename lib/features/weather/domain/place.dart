import 'package:freezed_annotation/freezed_annotation.dart';

part 'place.freezed.dart';
part 'place.g.dart';

/// A saved or searchable location.
///
/// [id] is Open-Meteo's geocoding id where one exists; locations resolved from
/// the device's GPS get a synthetic negative id so they never collide.
@freezed
abstract class Place with _$Place {
  const factory Place({
    required int id,
    required String name,
    required double latitude,
    required double longitude,
    String? country,
    String? admin1,
    String? timezone,
  }) = _Place;

  const Place._();

  factory Place.fromJson(Map<String, Object?> json) => _$PlaceFromJson(json);

  /// The id given to whatever the device's GPS resolved to.
  static const int currentLocationId = -1;

  bool get isCurrentLocation => id == currentLocationId;

  /// "Tokyo, Japan" — what the search results show under the name.
  String get subtitle => [admin1, country].nonNulls.join(', ');
}
