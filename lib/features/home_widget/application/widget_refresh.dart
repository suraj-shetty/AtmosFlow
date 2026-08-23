/// Fetching a forecast while the app is closed, so the widget is not simply
/// as old as the last time someone opened it.
///
/// The work runs in a headless isolate the OS starts: a second Dart isolate
/// with no UI, no navigation and no app state. It reuses the app's own
/// objects rather than a second implementation of them — the repository, the
/// formatter, [WidgetSnapshot], the publisher — which is what stops the
/// widget drifting away from what the app would have shown.
///
/// What this can promise is "best effort" and nothing firmer. iOS decides
/// when a `BGAppRefreshTask` runs from how the person actually uses the app;
/// a few times a day is a realistic outcome, hourly is not, and with
/// Background App Refresh off or Low Power Mode on it is never. Android is
/// steadier but still batches. The widget's own schedule is what makes that
/// acceptable: between fetches it still moves through the day correctly, and
/// says how old its numbers are.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/persistence/preferences.dart';
import '../../settings/application/settings_providers.dart';
import '../../weather/application/weather_providers.dart';
import '../domain/widget_snapshot.dart';
import 'widget_publisher.dart';

/// One name for three things that must agree: the BGTaskScheduler identifier
/// in `Info.plist`, the identifier `AppDelegate` registers a launch handler
/// for, and the unique name the work is scheduled under here. On iOS the
/// handler is even given this back as the task name, because the identifier
/// is all iOS knows about it.
const widgetRefreshTask = 'com.surajshetty.atmosFlow.refresh';

/// How often to ask for a run. A hint on both platforms, and a weaker one on
/// iOS than on Android.
const _refreshEvery = Duration(hours: 1);

/// A reading younger than this is not worth spending a fetch on. The app
/// itself publishes on every forecast it resolves, so a task waking moments
/// after someone closed the app would otherwise refetch what is already there.
const _skipIfFresherThan = Duration(minutes: 20);

/// The isolate's entry point. Must be top-level and must survive tree
/// shaking, which is what the pragma is for — nothing in the app calls it.
@pragma('vm:entry-point')
void widgetRefreshDispatcher() {
  Workmanager().executeTask((task, inputData) => refreshWidget());
}

/// Asks the OS to keep waking us. Idempotent: called on every launch, and
/// existing work is kept rather than replaced, so the countdown is not reset
/// every time the app opens.
Future<void> scheduleWidgetRefresh() async {
  try {
    await Workmanager().initialize(widgetRefreshDispatcher);
    await Workmanager().registerPeriodicTask(
      widgetRefreshTask,
      widgetRefreshTask,
      frequency: _refreshEvery,
      initialDelay: _refreshEvery,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  } catch (error, stack) {
    // A phone that will not schedule the work still runs the app perfectly
    // well, and the widget still advances through its own schedule.
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'atmos_flow',
        context: ErrorDescription('scheduling the widget refresh'),
      ),
    );
  }
}

/// One background run: read what the app has stored, fetch, publish.
///
/// Returns whether the run should be counted a success. A failure here is a
/// network that was not there, which is worth retrying later and is not worth
/// reporting — nobody is watching, and the widget goes on showing its last
/// good reading with an honest age against it.
///
/// [container] is the isolate's own — it builds one over the app's providers,
/// because the app's providers are the point. Tests pass their own, with a
/// repository that does not need the network.
Future<bool> refreshWidget({ProviderContainer? container}) async {
  final resolved =
      container ??
      ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
        ],
      );

  try {
    final place = resolved.read(selectedPlaceProvider);
    // Nothing chosen yet — onboarding has not finished. Not a failure.
    if (place == null) return true;
    if (await _publishedWithin(_skipIfFresherThan)) return true;

    final forecast = await resolved
        .read(weatherRepositoryProvider)
        .fetchForecast(place);

    await resolved
        .read(widgetPublisherProvider)
        .publish(
          WidgetSnapshot.of(forecast, resolved.read(unitFormatterProvider)),
        );
    return true;
  } catch (_) {
    return false;
  } finally {
    resolved.dispose();
  }
}

/// Whether the reading already in the widget's store is younger than [age].
///
/// Read back out of the store rather than tracked separately, because the
/// store is what the widget actually shows — and the app writes it too.
Future<bool> _publishedWithin(Duration age) async {
  await HomeWidget.setAppGroupId(WidgetPublisher.appGroup);
  final published = await HomeWidget.getWidgetData<String>('updatedAt');
  final seconds = int.tryParse(published ?? '');
  if (seconds == null) return false;

  final at = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  return DateTime.now().toUtc().difference(at) < age;
}
