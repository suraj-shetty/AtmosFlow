import WidgetKit

/// One reading, as the extension sees it.
struct WidgetEntry: TimelineEntry {
    var date: Date
    var condition: WidgetCondition
    var sky: WidgetSky
    var temperature: String
    var humidity: String
    var clock: String
    var place: String
    var caption: String
    var conditionLabel: String

    /// What the widget shows in the gallery, and before the app has ever run.
    static let placeholder = WidgetEntry(
        date: Date(),
        condition: .clear,
        sky: .afternoon,
        temperature: "22°",
        humidity: "58%",
        clock: "14:30",
        place: "San Francisco",
        caption: "Afternoon · Clear",
        conditionLabel: "Clear"
    )

    /// The last reading the app wrote to the shared App Group.
    ///
    /// The extension cannot fetch a forecast of its own, so an empty store
    /// means the app has not run yet — the placeholder stands in rather than
    /// an error, which is what the gallery preview wants anyway.
    static func fromSharedStore() -> WidgetEntry {
        guard let store = UserDefaults(suiteName: WidgetConfig.appGroup),
              let temperature = store.string(forKey: "temperature")
        else { return .placeholder }

        func value(_ key: String, _ fallback: String) -> String {
            store.string(forKey: key) ?? fallback
        }

        return WidgetEntry(
            date: Date(),
            condition: WidgetCondition(rawValue: value("condition", "clear")) ?? .clear,
            sky: WidgetSky(rawValue: value("sky", "afternoon")) ?? .afternoon,
            temperature: temperature,
            humidity: value("humidity", "—"),
            clock: value("clock", ""),
            place: value("place", ""),
            caption: value("caption", ""),
            conditionLabel: value("conditionLabel", "")
        )
    }
}

enum WidgetConfig {
    /// Must match `iOSAppGroup` in the app's widget publisher, and the App
    /// Group on both targets' entitlements.
    static let appGroup = "group.com.surajshetty.atmosFlow"
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(context.isPreview ? .placeholder : .fromSharedStore())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        // One entry, refreshed on the hour. The app pushes a new reading — and
        // reloads the timeline — every time it resolves a forecast, so this is
        // only the floor for a phone whose owner has not opened the app.
        let entry = WidgetEntry.fromSharedStore()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}
