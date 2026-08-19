import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main()` once `SharedPreferences` has loaded, so every
/// consumer can read it synchronously. Tests override it with
/// `SharedPreferences.setMockInitialValues({})`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

/// Keys live in one place so a rename can't silently orphan stored data.
abstract final class PrefKeys {
  static const savedLocations = 'atmos.savedLocations.v1';
  static const selectedPlaceId = 'atmos.selectedPlaceId.v1';
  static const settings = 'atmos.settings.v1';
  static const onboardingComplete = 'atmos.onboardingComplete.v1';
}
