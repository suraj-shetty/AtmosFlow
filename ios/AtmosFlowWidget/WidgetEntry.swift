import WidgetKit

/// One reading, resolved for the moment it is being drawn.
///
/// The sky and the age are not carried across from the app — they are worked
/// out here, per entry, from [WidgetReading]. A widget draws a reading that can
/// be hours old, so anything the app resolved against its own "now" would be
/// wrong by the time anyone looked at it.
struct WidgetEntry: TimelineEntry {
    var date: Date
    var condition: WidgetCondition
    var sky: WidgetSky
    var temperature: String
    var humidity: String
    var place: String
    var conditionLabel: String

    /// When the reading was taken, in the slot the design drew a clock in.
    ///
    /// Fresh, that is the hour on the place's own clock, in whichever of 12-
    /// and 24-hour the device is set to. It is not a live clock and cannot be
    /// one: WidgetKit's `.time` style is a fixed string, and ticking would
    /// cost a timeline entry every minute. Past `WidgetReading.staleAfter` it
    /// gives way to how old the reading is, because by then the hour it was
    /// taken at is no longer the fact worth printing.
    var stamp: String

    /// "Afternoon · Clear" — follows this entry's sky, not the app's.
    var caption: String { "\(sky.label) · \(condition.label)" }

    /// What the widget shows in the gallery, and before the app has ever run.
    static let placeholder = WidgetEntry(
        date: Date(),
        condition: .clear,
        sky: .afternoon,
        temperature: "22°",
        humidity: "58%",
        place: "San Francisco",
        conditionLabel: "Clear",
        stamp: "2:14 PM"
    )
}

/// The last reading the app left in the shared App Group, with everything it
/// needs to be drawn at any moment — not just the one it was written at.
struct WidgetReading {
    /// The sky becomes `sky` at `at`, and holds until the next change.
    struct SkyChange {
        var at: Date
        var sky: WidgetSky
    }

    var condition: WidgetCondition
    var conditionLabel: String
    var temperature: String
    var humidity: String
    var place: String
    var skyChanges: [SkyChange]
    var updatedAt: Date?

    /// The place's offset from UTC, in minutes — what turns `updatedAt` back
    /// into the hour it was on the clock there.
    var utcOffsetMinutes: Int

    /// How far ahead a timeline runs. Matches the window the app builds its
    /// schedule over — past it there are no more sky changes to draw.
    static let horizon: TimeInterval = 36 * 3600

    /// The extension cannot fetch a forecast of its own, so an empty store
    /// means the app has not run yet — the caller stands the placeholder in
    /// rather than an error, which is what the gallery preview wants anyway.
    static func fromSharedStore() -> WidgetReading? {
        guard let store = UserDefaults(suiteName: WidgetConfig.appGroup),
              let temperature = store.string(forKey: "temperature")
        else { return nil }

        func value(_ key: String, _ fallback: String) -> String {
            store.string(forKey: key) ?? fallback
        }

        return WidgetReading(
            condition: WidgetCondition(rawValue: value("condition", "clear")) ?? .clear,
            conditionLabel: value("conditionLabel", ""),
            temperature: temperature,
            humidity: value("humidity", "—"),
            place: value("place", ""),
            skyChanges: parseSchedule(value("skySchedule", "")),
            updatedAt: TimeInterval(value("updatedAt", ""))
                .map(Date.init(timeIntervalSince1970:)),
            utcOffsetMinutes: Int(value("utcOffsetMinutes", "")) ?? 0
        )
    }

    /// `<epochSeconds>:<sky>` pairs, comma separated. Anything unreadable is
    /// dropped rather than defaulted — a missing change leaves the previous
    /// sky standing, which is the older behaviour and not worth a crash.
    static func parseSchedule(_ raw: String) -> [SkyChange] {
        raw.split(separator: ",").compactMap { pair in
            let halves = pair.split(separator: ":")
            guard halves.count == 2,
                  let seconds = TimeInterval(halves[0]),
                  let sky = WidgetSky(rawValue: String(halves[1]))
            else { return nil }
            return SkyChange(at: Date(timeIntervalSince1970: seconds), sky: sky)
        }
    }

    /// The sky in force at `date` — the last change to have happened, or the
    /// first on record if `date` precedes them all.
    func sky(at date: Date) -> WidgetSky {
        var current = skyChanges.first?.sky ?? .afternoon
        for change in skyChanges {
            if change.at > date { break }
            current = change.sky
        }
        return current
    }

    func entry(at date: Date) -> WidgetEntry {
        WidgetEntry(
            date: date,
            condition: condition,
            sky: sky(at: date),
            temperature: temperature,
            humidity: humidity,
            place: place,
            conditionLabel: conditionLabel,
            stamp: stamp(at: date, clock: clock)
        )
    }

    /// Past this the hour a reading was taken stops being the useful fact and
    /// its age takes over. Matched by `WidgetReading.STALE_AFTER_SECONDS` on
    /// Android.
    static let staleAfter: TimeInterval = 3 * 3600

    /// The clock, or the age once the reading is old enough that the clock
    /// would be quietly misleading.
    ///
    /// `clock` is passed in rather than reached for so the rule can be tested
    /// without the device's own locale deciding the answer.
    func stamp(at date: Date, clock: (Date) -> String) -> String {
        guard let updatedAt else { return "" }
        let seconds = max(0, date.timeIntervalSince(updatedAt))
        return seconds < WidgetReading.staleAfter
            ? clock(updatedAt)
            : WidgetReading.age(of: updatedAt, at: date)
    }

    /// An instant on the place's clock, in the device's own 12- or 24-hour
    /// format. `.short` is what follows the Settings toggle; a hand-written
    /// format string would not.
    func clock(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = TimeZone(secondsFromGMT: utcOffsetMinutes * 60)
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Deliberately coarse. The tile has room for a couple of words, and to
    /// the minute is a precision nobody reads a weather widget for.
    static func age(of updatedAt: Date?, at date: Date) -> String {
        guard let updatedAt else { return "" }
        let seconds = max(0, date.timeIntervalSince(updatedAt))
        switch seconds {
        case ..<120: return "Just now"
        case ..<3600: return "\(Int(seconds / 60))m ago"
        case ..<86_400: return "\(Int(seconds / 3600))h ago"
        case ..<172_800: return "Yesterday"
        default: return "\(Int(seconds / 86_400))d ago"
        }
    }

    /// The moments worth redrawing between `start` and the horizon: every sky
    /// change, and an hourly tick so the age keeps up with itself.
    func moments(from start: Date) -> [Date] {
        let horizon = start.addingTimeInterval(WidgetReading.horizon)
        var moments: Set<Date> = [start]

        for change in skyChanges where change.at > start && change.at < horizon {
            moments.insert(change.at)
        }

        var tick = start.addingTimeInterval(3600)
        while tick < horizon {
            moments.insert(tick)
            tick = tick.addingTimeInterval(3600)
        }

        return moments.sorted()
    }
}

enum WidgetConfig {
    /// Must match `WidgetPublisher.appGroup` in the app, and the App Group on
    /// both targets' entitlements.
    static let appGroup = "group.com.surajshetty.atmosFlow"
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        guard !context.isPreview, let reading = WidgetReading.fromSharedStore() else {
            completion(.placeholder); return
        }
        completion(reading.entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let now = Date()
        guard let reading = WidgetReading.fromSharedStore() else {
            // Nothing published yet. Ask again in an hour rather than never —
            // the app may run in the meantime, though it also reloads us
            // itself the moment it does.
            completion(Timeline(entries: [.placeholder],
                                policy: .after(now.addingTimeInterval(3600))))
            return
        }

        // One entry per moment the tile would actually look different, rather
        // than one entry re-read on the hour: the app only republishes when it
        // runs, so without these the sky it was written under would hold all
        // night. `.atEnd` asks for a fresh set once they run out.
        let entries = reading.moments(from: now).map(reading.entry(at:))
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
