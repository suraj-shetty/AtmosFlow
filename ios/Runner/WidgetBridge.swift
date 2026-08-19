import Flutter
import WidgetKit

/// Carries the app's latest reading across to the widget extension.
///
/// The extension is a separate process with its own container, so the only
/// thing the two share is the App Group — the app writes there, then asks
/// WidgetKit to redraw.
enum WidgetBridge {
    static let channelName = "com.surajshetty.atmos_flow/widget"

    /// Must match the App Group on both targets' entitlements, and
    /// `WidgetConfig.appGroup` in the extension.
    static let appGroup = "group.com.surajshetty.atmosFlow"

    static func register(with registrar: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar)
        channel.setMethodCallHandler { call, result in
            guard call.method == "publish" else {
                result(FlutterMethodNotImplemented); return
            }
            guard let values = call.arguments as? [String: String] else {
                result(FlutterError(code: "bad-arguments",
                                    message: "publish expects a map of strings",
                                    details: nil))
                return
            }
            publish(values)
            result(nil)
        }
    }

    private static func publish(_ values: [String: String]) {
        guard let store = UserDefaults(suiteName: appGroup) else { return }
        for (key, value) in values {
            store.set(value, forKey: key)
        }
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
