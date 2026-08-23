import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../settings/application/settings_providers.dart';
import '../../weather/application/weather_providers.dart';
import '../domain/widget_snapshot.dart';

/// Pushes the current forecast out to the home-screen widgets.
///
/// The widgets are separate processes that cannot call the weather API on
/// their own — they draw whatever the app last left in the shared store, so
/// every forecast the app resolves is written straight back out.
///
/// This used to be a hand-rolled method channel, which was the smaller thing
/// while only a running app published. A background refresh does not run in
/// the app: it runs in a headless engine, and a headless engine registers the
/// plugins the tool generated for it and nothing else — a channel wired up in
/// `MainActivity` or off the implicit iOS engine is simply not there. Going
/// through a plugin is what makes the two paths the same path.
class WidgetPublisher {
  const WidgetPublisher();

  /// Must match the App Group on both iOS targets' entitlements, and
  /// `WidgetConfig.appGroup` in the extension.
  static const appGroup = 'group.com.surajshetty.atmosFlow';

  /// The `kind` each WidgetKit configuration is declared with, in
  /// `AtmosFlowWidget.swift`. Reloading is per kind, so both are named.
  static const _iOSKinds = ['AtmosFlowWidget', 'AtmosFlowAccessory'];

  /// The `AppWidgetProvider` to poke, fully qualified — it does not sit
  /// directly under the application id.
  static const _androidProvider =
      'com.surajshetty.atmos_flow.widget.AtmosFlowWidgetProvider';

  Future<void> publish(WidgetSnapshot snapshot) async {
    try {
      await HomeWidget.setAppGroupId(appGroup);
      for (final entry in snapshot.toStore().entries) {
        await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
      }
      // Written first, then asked to redraw — the reload picks up whatever is
      // in the store at the moment it lands.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        for (final kind in _iOSKinds) {
          await HomeWidget.updateWidget(iOSName: kind);
        }
      } else {
        await HomeWidget.updateWidget(qualifiedAndroidName: _androidProvider);
      }
    } catch (error, stack) {
      // A widget that fails to refresh is not worth taking the app down for —
      // it keeps showing its last good reading either way. In a background
      // isolate there is nobody to tell at all.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'atmos_flow',
          context: ErrorDescription('publishing the home-screen widget'),
        ),
      );
    }
  }
}

final widgetPublisherProvider = Provider<WidgetPublisher>(
  (ref) => const WidgetPublisher(),
);

/// Watches the forecast Home is showing and mirrors it to the widgets.
///
/// Kept alive for the app's lifetime so it also catches a refresh the user
/// triggers from a screen that is not Home.
final widgetMirrorProvider = Provider<void>((ref) {
  final formatter = ref.watch(unitFormatterProvider);
  final forecast = ref.watch(currentForecastProvider)?.value;
  if (forecast == null) return;

  ref
      .read(widgetPublisherProvider)
      .publish(WidgetSnapshot.of(forecast, formatter));
});
