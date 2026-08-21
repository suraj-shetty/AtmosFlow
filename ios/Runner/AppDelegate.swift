import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Under the scene lifecycle there is no window to reach through at launch —
  /// the engine is created by the scene's storyboard, later. Both the plugins
  /// and the widget channel are wired here instead, off the engine itself,
  /// which is the only moment guaranteed to have one.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    WidgetBridge.register(with: engineBridge.applicationRegistrar.messenger())
  }
}
