import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// The identifier the background refresh is scheduled under. Must match
  /// `widgetRefreshTask` in Dart and `BGTaskSchedulerPermittedIdentifiers`
  /// in Info.plist.
  private static let refreshTask = "com.surajshetty.atmosFlow.refresh"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // iOS only hands a background task to an app whose launch handler was
    // registered before this method returned — and under the scene lifecycle
    // Flutter registers its plugins later, when the scene connects. So the
    // one thing that cannot wait for `didInitializeImplicitFlutterEngine` is
    // done here instead, off the plugin's own public entry point. Without it
    // the task is scheduled, granted, and then dropped on the doorstep.
    WorkmanagerPlugin.registerPeriodicTask(withIdentifier: Self.refreshTask)

    // The refresh runs in a headless engine, which is registered with
    // nothing until it is told. Everything the background isolate touches —
    // shared_preferences to find the place, home_widget to publish the
    // result — has to be registered here or it is simply not there.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Under the scene lifecycle there is no window to reach through at launch —
  /// the engine is created by the scene's storyboard, later. The plugins are
  /// wired here instead, off the engine itself, which is the only moment
  /// guaranteed to have one.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
