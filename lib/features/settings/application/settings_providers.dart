import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/preferences.dart';
import '../domain/app_settings.dart';
import 'unit_formatter.dart';

/// Unit and appearance preferences, written through to disk on every change.
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final raw = ref
        .read(sharedPreferencesProvider)
        .getString(PrefKeys.settings);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      // A settings blob we can't read is not worth failing startup over.
      return const AppSettings();
    }
  }

  void setTemperatureUnit(TemperatureUnit unit) =>
      _write(state.copyWith(temperatureUnit: unit));

  void setWindUnit(WindUnit unit) => _write(state.copyWith(windUnit: unit));

  void setAppearance(AppearanceMode mode) =>
      _write(state.copyWith(appearance: mode));

  void _write(AppSettings next) {
    state = next;
    ref
        .read(sharedPreferencesProvider)
        .setString(PrefKeys.settings, jsonEncode(next.toJson()));
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// The formatter every screen uses to render temperatures and wind speeds.
final unitFormatterProvider = Provider<UnitFormatter>(
  (ref) => UnitFormatter(ref.watch(settingsProvider)),
);
