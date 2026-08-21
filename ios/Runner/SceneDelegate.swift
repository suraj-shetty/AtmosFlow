import Flutter
import UIKit

/// iOS 26 requires apps to adopt the `UIScene` lifecycle: the window is owned
/// by a scene now, not by the app delegate. `FlutterSceneDelegate` does all of
/// the work — this exists only so `Info.plist` has a class in this module to
/// name, leaving somewhere obvious to hook scene events if they are ever
/// needed.
class SceneDelegate: FlutterSceneDelegate {}
