import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_providers.dart';
import '../../weather/application/weather_providers.dart';
import '../domain/widget_snapshot.dart';

/// The channel the two native sides listen on.
///
/// Hand-rolled rather than taken from a package: all it carries is a flat map
/// of strings one way, and each platform then does something entirely its own
/// with it — an App Group write and a WidgetKit reload on iOS, a
/// SharedPreferences write and an AppWidgetManager notify on Android.
@visibleForTesting
const widgetChannel = MethodChannel('com.surajshetty.atmos_flow/widget');

/// Pushes the current forecast out to the home-screen widgets.
///
/// The widgets are separate processes that cannot call the weather API on
/// their own — they draw whatever the app last left in the shared store, so
/// every forecast the app resolves is written straight back out.
class WidgetPublisher {
  const WidgetPublisher();

  Future<void> publish(WidgetSnapshot snapshot) async {
    try {
      await widgetChannel.invokeMethod<void>('publish', snapshot.toStore());
    } catch (error, stack) {
      // A widget that fails to refresh is not worth taking the app down for —
      // it keeps showing its last good reading either way.
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
