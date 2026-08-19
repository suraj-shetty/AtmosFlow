import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_failure.freezed.dart';

/// Everything that can go wrong, as a closed set the UI can exhaustively
/// switch over. Repositories throw these; `AsyncValue.error` carries them.
@freezed
sealed class AppFailure with _$AppFailure implements Exception {
  /// The request never completed — offline, timeout, DNS, 5xx.
  const factory AppFailure.network({String? detail}) = NetworkFailure;

  /// The API answered, but with nothing for this place or query.
  const factory AppFailure.notFound({String? detail}) = NotFoundFailure;

  /// Location permission was denied, or services are switched off.
  const factory AppFailure.locationDenied({@Default(false) bool permanently}) =
      LocationDeniedFailure;

  /// The response arrived but did not look like what we asked for.
  const factory AppFailure.malformedResponse({String? detail}) =
      MalformedResponseFailure;

  const factory AppFailure.unknown({String? detail}) = UnknownFailure;

  const AppFailure._();

  /// Copy safe to show the user.
  String get message => switch (this) {
    NetworkFailure() => "Couldn't reach the forecast. Check your connection.",
    NotFoundFailure() => 'No forecast for that location.',
    LocationDeniedFailure(:final permanently) =>
      permanently
          ? 'Location access is off. Enable it in Settings to use your location.'
          : 'Location access is needed to show your local forecast.',
    MalformedResponseFailure() =>
      'The forecast came back in a format we could not read.',
    UnknownFailure() => 'Something went wrong. Pull to try again.',
  };
}
