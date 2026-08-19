import SwiftUI
import WidgetKit

/// The three home-screen sizes, each showing the design tile whose proportions
/// and layout match it.
///
/// The design names its three tiles for iOS surfaces that cannot actually
/// carry them — a Lock Screen widget is monochrome, and a Control Center
/// control is a button with a symbol, so neither can render a colour gradient
/// with a sun in it. What the three tiles really are is one square layout at
/// two type scales and one landscape layout, which is exactly the set of
/// home-screen families WidgetKit offers:
///
/// - `systemSmall` gets the 160pt tile,
/// - `systemLarge` gets the 200pt tile, whose larger type suits the bigger box,
/// - `systemMedium` gets the landscape tile the design draws for Android.
struct AtmosFlowWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AtmosFlowWidget", provider: Provider()) { entry in
            AtmosFlowWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    entry.sky.gradient
                }
        }
        .configurationDisplayName("AtmosFlow")
        .description("Your sky, beautifully forecasted.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

private struct AtmosFlowWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: WidgetEntry

    var body: some View {
        switch family {
        case .systemMedium: WideWidgetView(entry: entry)
        case .systemLarge: SquareWidgetView(entry: entry)
        default: SmallWidgetView(entry: entry)
        }
    }
}

/// The genuine Lock Screen surface.
///
/// iOS renders accessory widgets through a monochrome vibrancy filter, so the
/// sky cannot come along — what survives is the reading itself, in the same
/// order the design puts it in.
struct AtmosFlowAccessoryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AtmosFlowAccessory", provider: Provider()) { entry in
            HStack(spacing: 8) {
                WeatherGlyph(condition: entry.condition, sky: entry.sky,
                             size: 22, color: .white)
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.temperature).font(.system(size: 22, weight: .light))
                    Text(entry.caption).font(.system(size: 11))
                }
                Spacer(minLength: 0)
            }
            .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("AtmosFlow")
        .description("The current sky, on your Lock Screen.")
        .supportedFamilies([.accessoryRectangular])
    }
}

@main
struct AtmosFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        AtmosFlowWidget()
        AtmosFlowAccessoryWidget()
    }
}
